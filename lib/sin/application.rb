module Sin
  class Application
    # Hash of event handlers with request method keys and
    # arrays of potential handlers as values.
    attr_reader :events

    # Hash of error handlers with error status codes as keys and
    # handlers as values.
    attr_reader :errors

    # Hash of template name mappings.
    attr_reader :templates

    # Hash of filters with event name keys (:before) and arrays of
    # handlers as values.
    attr_reader :filters

    # Array of objects to clear during reload. The objects in this array
    # must respond to :clear.
    attr_reader :clearables

    # Object including open attribute methods for modifying Application
    # configuration.
    attr_reader :options

    # Where the app definition methods live, such as #get and #post. This is
    # the scope where user facing code is executed.
    attr_reader :dsl

    # Hash of default application configuration options. When a new
    # Application is created, the #options object takes its initial values
    # from here.
    #
    # Changes to the default_options Hash effect only Application objects
    # created after the changes are made. For this reason, modifications to
    # the default_options Hash typically occur at the very beginning of a
    # file, before any DSL related functions are invoked.
    def self.default_options
      return @default_options unless @default_options.nil?
      root = Dir.pwd
      @default_options = {
        :port => 4567,
        :host => '0.0.0.0',
        :env => :development,
        :root => root,
        :views => root + '/views',
        :public => root + '/public',
        :app_file => $0,
        :raise_errors => false
      }
      @default_options
    end

    # Create a new Application
    def initialize(options = {}, &blk)
      @reloading = false
      @clearables = [
        @events = Hash.new { |hash, key| hash[key] = [] },
        @errors = Hash.new,
        @filters = Hash.new { |hash, key| hash[key] = [] },
        @templates = Hash.new
      ]
      @options = self.class.default_options.merge(options)
      @dsl = Dsl.new(self)

      load_default_configuration!
      load_development_configuration! if @options[:env] == :development

      from_code(&blk) if blk
    end
    
    def from_code(&blk)
      @dsl.eval &blk
    end
    
    def from_file(f)
      @dsl.eval File.read(f)
    end

    # Determine whether the application is in the process of being
    # reloaded.
    def reloading?
      @reloading == true
    end

    # Visits and invokes each handler registered for the +request_method+ in
    # definition order until a Result response is produced. If no handler
    # responds with a Result, the NotFound error handler is invoked.
    #
    # When the request_method is "HEAD" and no valid Result is produced by
    # the set of handlers registered for HEAD requests, an attempt is made to
    # invoke the GET handlers to generate the response before resorting to the
    # default error handler.
    def lookup(request)
      method = request.request_method.downcase.to_sym
      events[method].eject(&[:invoke, request]) ||
      (events[:get].eject(&[:invoke, request]) if method == :head) ||
      errors[NotFound].invoke(request)
    end

    # Clear all events, templates, filters, and error handlers
    # and then reload the application source file. This occurs
    # automatically before each request is processed in development.
    def reload!
      clearables.each { |o| o.clear }
      load_default_configuration!
      load_development_configuration! if options[:env] == :development
      @reloading = true
      Kernel.load options[:app_file]
      @reloading = false
    end

    # Mutex instance used for thread synchronization.
    def mutex
      @mutex ||= Mutex.new
    end

    # Yield to the block with thread synchronization
    def run_safely
      if options[:mutex]
        mutex.synchronize { yield }
      else
        yield
      end
    end

    # Rack compatible request invocation interface.
    def call(env)
      run_safely do
        reload! if options[:reload]
        dispatch(env)
      end
    end

    # Request invocation handler - called at the end of the Rack pipeline
    # for each request.
    #
    # 1. Create Rack::Request, Rack::Response helper objects.
    # 2. Lookup event handler based on request method and path.
    # 3. Create new EventContext to house event handler evaluation.
    # 4. Invoke each #before filter in context of EventContext object.
    # 5. Invoke event handler in context of EventContext object.
    # 6. Return response to Rack.
    #
    # See the Rack specification for detailed information on the
    # +env+ argument and return value.
    def dispatch(env)
      request = Request.new(env)
      context = EventContext.new(self, request, Rack::Response.new([], 200), {})
      begin
        returned =
        catch(:halt) do
          filters[:before].each { |f| context.instance_eval(&f) }
          result = lookup(context.request)
          context.route_params = result.params
          context.response.status = result.status
          context.reset!
          [:complete, context.instance_eval(&result.block)]
        end
        body = returned.to_result(context)
      rescue => e
        request.env['sin.error'] = e
        context.status(500)
        raise if options[:raise_errors] && e.class != NotFound
        result = (errors[e.class] || errors[ServerError]).invoke(request)
        returned =
        catch(:halt) do
          [:complete, context.instance_eval(&result.block)]
        end
        body = returned.to_result(context)
      end
      body = '' unless body.respond_to?(:each)
      body = '' if request.env["REQUEST_METHOD"].upcase == 'HEAD'
      context.body = body.kind_of?(String) ? [*body] : body
      context.response['Content-Length'] ||= body.size.to_s if body.respond_to?(:size)
      context.finish
    end

    private

    # Called immediately after the application is initialized or reloaded to
    # register default events, templates, and error handlers.
    def load_default_configuration!
      events[:get] << Static.new(self)
      @dsl.configure do |dsl|
        dsl.error do
          '<h1>Internal Server Error</h1>'
        end
        dsl.not_found { '<h1>Not Found</h1>'}
      end
    end

    # Called before reloading to perform development specific configuration.
    def load_development_configuration!
      @dsl.configure do |dsl|
        dsl.not_found do
          (<<-HTML).gsub(/^ {8}/, '')
          <!DOCTYPE html>
          <html>
          <head>
            <style type="text/css">
            body {text-align:center;color:#888;font-family:arial;font-size:22px;margin:20px;}
            #content {margin:0 auto;width:500px;text-align:left}
            </style>
          </head>
          <body>
            <h2>Sin couldn't be found.</h2>
            <div id="content">
              Try this:
              <pre>#{request.request_method.downcase} "#{request.path_info}" do\n  .. do something ..\nend</pre>
            </div>
          </body>
          </html>
          HTML
        end

        dsl.error do
          @error = request.env['sin.error']
          (<<-HTML).gsub(/^ {8}/, '')
          <!DOCTYPE html>
          <html>
          <head>
            <style type="text/css" media="screen">
            body {font-family:verdana;color:#333}
            #content {width:700px;margin-left:20px}
            #content h1 {width:99%;color:#1D6B8D;font-weight:bold}
            #stacktrace {margin-top:-20px}
            #stacktrace pre {font-size:12px;border-left:2px solid #ddd;padding-left:10px}
            #stacktrace img {margin-top:10px}
            </style>
            <title>Eternal Sin</title>
          </head>
          <body>
            <div id="content">
              <div class="info">
                Params: <pre>#{params.inspect}</pre>
              </div>
              <div id="stacktrace">
                <h1>#{escape_html(@error.class.name + ' - ' + @error.message.to_s)}</h1>
                <pre><code>#{escape_html(@error.backtrace.join("\n"))}</code></pre>
              </div>
            </div>
          </body>
          </html>
          HTML
        end
      end
    end

  end
end