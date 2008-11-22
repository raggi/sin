module Sin
  # Helper methods for building various aspects of the HTTP response.
  module ResponseHelpers

    # Immediately halt response execution by redirecting to the resource
    # specified. The +path+ argument may be an absolute URL or a path
    # relative to the site root. Additional arguments are passed to the
    # halt.
    #
    # With no integer status code, a '302 Temporary Redirect' response is
    # sent. To send a permanent redirect, pass an explicit status code of
    # 301:
    #
    #   redirect '/somewhere/else', 301
    #
    # NOTE: No attempt is made to rewrite the path based on application
    # context. The 'Location' response header is set verbatim to the value
    # provided.
    def redirect(path, *args)
      status(302)
      header 'Location' => path
      throw :halt, *args
    end

    # Access or modify response headers. With no argument, return the
    # underlying headers Hash. With a Hash argument, add or overwrite
    # existing response headers with the values provided:
    #
    #    headers 'Content-Type' => "text/html;charset=utf-8",
    #      'Last-Modified' => Time.now.httpdate,
    #      'X-UA-Compatible' => 'IE=edge'
    #
    # This method also available in singular form (#header).
    def headers(header = nil)
      @response.headers.merge!(header) if header
      @response.headers
    end
    alias :header :headers

    # Set the content type of the response body (HTTP 'Content-Type' header).
    #
    # The +type+ argument may be an internet media type (e.g., 'text/html',
    # 'application/xml+atom', 'image/png') or a Symbol key into the
    # Rack::File::MIME_TYPES table.
    #
    # Media type parameters, such as "charset", may also be specified using the
    # optional hash argument:
    #
    #   get '/foo.html' do
    #     content_type 'text/html', :charset => 'utf-8'
    #     "<h1>Hello World</h1>"
    #   end
    #
    def content_type(type, params={})
      type = Rack::File::MIME_TYPES[type.to_s] if type.kind_of?(Symbol)
      fail "Invalid or undefined media_type: #{type}" if type.nil?
      if params.any?
        params = params.collect { |kv| "%s=%s" % kv }.join(', ')
        type = [ type, params ].join(";")
      end
      response.header['Content-Type'] = type
    end

    # Set the last modified time of the resource (HTTP 'Last-Modified' header)
    # and halt if conditional GET matches. The +time+ argument is a Time,
    # DateTime, or other object that responds to +to_time+.
    #
    # When the current request includes an 'If-Modified-Since' header that
    # matches the time specified, execution is immediately halted with a
    # '304 Not Modified' response.
    #
    # Calling this method before perfoming heavy processing (e.g., lengthy
    # database queries, template rendering, complex logic) can dramatically
    # increase overall throughput with caching clients.
    def last_modified(time)
      time = time.to_time if time.respond_to?(:to_time)
      time = time.httpdate if time.respond_to?(:httpdate)
      response.header['Last-Modified'] = time
      throw :halt, 304 if time == request.env['HTTP_IF_MODIFIED_SINCE']
      time
    end

    # Set the response entity tag (HTTP 'ETag' header) and halt if conditional
    # GET matches. The +value+ argument is an identifier that uniquely
    # identifies the current version of the resource. The +strength+ argument
    # indicates whether the etag should be used as a :strong (default) or :weak
    # cache validator.
    #
    # When the current request includes an 'If-None-Match' header with a
    # matching etag, execution is immediately halted. If the request method is
    # GET or HEAD, a '304 Not Modified' response is sent. For all other request
    # methods, a '412 Precondition Failed' response is sent.
    #
    # Calling this method before perfoming heavy processing (e.g., lengthy
    # database queries, template rendering, complex logic) can dramatically
    # increase overall throughput with caching clients.
    #
    # ==== See Also
    # {RFC2616: ETag}[http://w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.19],
    # ResponseHelpers#last_modified
    def entity_tag(value, strength=:strong)
      value =
      case strength
      when :strong then '"%s"' % value
      when :weak   then 'W/"%s"' % value
      else         raise TypeError, "strength must be one of :strong or :weak"
      end
      response.header['ETag'] = value

      # Check for If-None-Match request header and halt if match is found.
      etags = (request.env['HTTP_IF_NONE_MATCH'] || '').split(/\s*,\s*/)
      if etags.include?(value) || etags.include?('*')
        # GET/HEAD requests: send Not Modified response
        throw :halt, 304 if request.get? || request.head?
        # Other requests: send Precondition Failed response
        throw :halt, 412
      end
    end

    alias :etag :entity_tag

  end
end