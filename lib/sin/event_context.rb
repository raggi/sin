module Sin
  class EventContext
    include Utils
    include ResponseHelpers
    include Streaming
    include RenderingHelpers
    include Erb
    include Haml
    include Builder
    include Sass

    attr_accessor :request, :response

    attr_accessor :route_params

    def initialize(request, response, route_params)
      @params = nil
      @data = nil
      @request = request
      @response = response
      @route_params = route_params
      @response.body = nil
    end

    def status(value=nil)
      response.status = value if value
      response.status
    end

    def body(value=nil)
      response.body = value if value
      response.body
    end

    def params
      @params ||=
        begin
          hash = Hash.new {|h,k| h[k.to_s] if Symbol === k}
          hash.merge! @request.params
          hash.merge! @route_params
          hash
        end
    end

    def data
      @data ||= params.keys.first
    end

    def stop(*args)
      throw :halt, args
    end

    def complete(returned)
      @response.body || returned
    end

    def session
      request.env['rack.session'] ||= {}
    end

    def reset!
      @params = nil
      @data = nil
    end

  private

    def method_missing(name, *args, &b)
      if @response.respond_to?(name)
        @response.send(name, *args, &b)
      else
        super
      end
    end

  end
end