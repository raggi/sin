module Sin
  class Request < Rack::Request
    # Set of request method names allowed via the _method parameter hack. By
    # default, all request methods defined in RFC2616 are included, with the
    # exception of TRACE and CONNECT.
    POST_TUNNEL_METHODS_ALLOWED = %w( PUT DELETE OPTIONS HEAD )

    # Return the HTTP request method with support for method tunneling using
    # the POST _method parameter hack. If the real request method is POST and
    # a _method param is given and the value is one defined in
    # +POST_TUNNEL_METHODS_ALLOWED+, return the value of the _method param
    # instead.
    def request_method
      if post_tunnel_method_hack?
        params['_method'].upcase
      else
        @env['REQUEST_METHOD']
      end
    end

    def user_agent
      @env['HTTP_USER_AGENT']
    end

    private

    # Return truthfully if the request is a valid verb-over-post hack.
    def post_tunnel_method_hack?
      @env['REQUEST_METHOD'] == 'POST' &&
      POST_TUNNEL_METHODS_ALLOWED.include?(self.POST.fetch('_method', '').upcase)
    end
  end
end