module Sin  
  class Dsl
    def initialize(app)
      @app = app
      mime :xml, 'application/xml'
      mime :js,  'application/javascript'
      mime :png, 'image/png'
    end
    
    def eval(code = nil, &blk)
      if code
        self.instance_eval code
      else
        self.instance_eval &blk
      end
    end
    
    # Yield to the block for configuration if the current environment
    # matches any included in the +envs+ list. Always yield to the block
    # when no environment is specified.
    #
    # NOTE: configuration blocks are not executed during reloads.
    def configures(*envs, &b)
      return if @app.reloading?
      yield self if envs.empty? || envs.include?(@app.options[:env])
    end

    alias :configure :configures
    
    # When both +option+ and +value+ arguments are provided, set the option
    # specified. With a single Hash argument, set all options specified in
    # Hash. Options are available via the Application#options object.
    #
    # Setting individual options:
    #   set :port, 80
    #   set :env, :production
    #   set :views, '/path/to/views'
    #
    # Setting multiple options:
    #   set :port  => 80,
    #       :env   => :production,
    #       :views => '/path/to/views'
    #
    def set(option, value=self)
      if value == self && option.kind_of?(Hash)
        @app.options.merge!(option)
      else
        @app.options.merge!(option => value)
      end
    end
    
    alias :set_option :set
    alias :set_options :set

    # Enable the options specified by setting their values to true. For
    # example, to enable sessions and logging:
    #   enable :sessions, :logging
    def enable(*opts)
      opts.each { |key| set(key, true) }
    end

    # Disable the options specified by setting their values to false. For
    # example, to disable logging and automatic run:
    #   disable :logging, :run
    def disable(*opts)
      opts.each { |key| set(key, false) }
    end
    
    # Define an event handler for the given request method and path
    # spec. The block is executed when a request matches the method
    # and spec.
    #
    # NOTE: The #get, #post, #put, and #delete helper methods should
    # be used to define events when possible.
    def event(method, path, options = {}, &b)
      @app.events[method].push(Event.new(path, options, &b)).last
    end

    # Define an event handler for GET requests.
    def get(path, options={}, &b)
      event(:get, path, options, &b)
    end

    # Define an event handler for POST requests.
    def post(path, options={}, &b)
      event(:post, path, options, &b)
    end

    # Define an event handler for HEAD requests.
    def head(path, options={}, &b)
      event(:head, path, options, &b)
    end

    # Define an event handler for PUT requests.
    #
    # NOTE: PUT events are triggered when the HTTP request method is
    # PUT and also when the request method is POST and the body includes a
    # "_method" parameter set to "PUT".
    def put(path, options={}, &b)
      event(:put, path, options, &b)
    end

    # Define an event handler for DELETE requests.
    #
    # NOTE: DELETE events are triggered when the HTTP request method is
    # DELETE and also when the request method is POST and the body includes a
    # "_method" parameter set to "DELETE".
    def delete(path, options={}, &b)
      event(:delete, path, options, &b)
    end
    
    # Define a named template. The template may be referenced from
    # event handlers by passing the name as a Symbol to rendering
    # methods. The block is executed each time the template is rendered
    # and the resulting object is passed to the template handler.
    #
    # The following example defines a HAML template named hello and
    # invokes it from an event handler:
    #
    #   template :hello do
    #     "h1 Hello World!"
    #   end
    #
    #   get '/' do
    #     haml :hello
    #   end
    #
    def template(name, &b)
      @app.templates[name] = b
    end

    # Define a layout template.
    def layout(name=:layout, &b)
      template(name, &b)
    end

    # Define a custom error handler for the exception class +type+. The block
    # is invoked when the specified exception type is raised from an error
    # handler and can manipulate the response as needed:
    #
    #   error MyCustomError do
    #     status 500
    #     'So what happened was...' + request.env['sinatra.error'].message
    #   end
    #
    # The Sin::ServerError handler is used by default when an exception
    # occurs and no matching error handler is found.
    def error(type=ServerError, options = {}, &b)
      @app.errors[type] = Error.new(type, options, &b)
    end

    # Define a custom error handler for '404 Not Found' responses. This is a
    # shorthand for:
    #   error NotFound do
    #     ..
    #   end
    def not_found(options={}, &b)
      error NotFound, options, &b
    end

    # Define a request filter. When <tt>type</tt> is <tt>:before</tt>, execute the
    # block in the context of each request before matching event handlers.
    def filter(type, &b)
      @app.filters[type] << b
    end

    # Invoke the block in the context of each request before invoking
    # matching event handlers.
    def before(&b)
      filter :before, &b
    end
    
    def mime(ext, type)
      Rack::File::MIME_TYPES[ext.to_s] = type
    end
    
    def helpers(&b)
      Sin::EventContext.class_eval(&b)
    end
    
    def use_in_file_templates!
      require 'stringio'
      templates = IO.read(caller.first.split(':').first).split('__FILE__').last
      data = StringIO.new(templates)
      current_template = nil
      data.each do |line|
        if line =~ /^@@\s?(.*)/
          current_template = $1.to_sym
          @app.templates[current_template] = ''
        elsif current_template
          @app.templates[current_template] << line
        end
      end
    end
    
    # True when environment is :development.
    def development? ; @app.options[:env] == :development ; end

    # True when environment is :test.
    def test? ; @app.options[:env] == :test ; end

    # True when environment is :production.
    def production? ; @app.options[:env] == :production ; end

  end
end