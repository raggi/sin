module Sin
  # Methods for sending files and streams to the browser instead of rendering.
  module Streaming
    DEFAULT_SEND_FILE_OPTIONS = {
      :type         => 'application/octet-stream'.freeze,
      :disposition  => 'attachment'.freeze,
      :stream       => true,
      :buffer_size  => 8192
    }.freeze

    class MissingFile < RuntimeError; end

    class FileStreamer
      attr_reader :path, :options

      def initialize(path, options)
        @path, @options = path, options
      end

      def to_result(cx, *args)
        self
      end

      def each
        size = options[:buffer_size]
        File.open(path, 'rb') do |file|
          while buf = file.read(size)
            yield buf
          end
        end
      end
    end

  protected
    # Sends the file by streaming it 8192 bytes at a time. This way the
    # whole file doesn't need to be read into memory at once.  This makes
    # it feasible to send even large files.
    #
    # Be careful to sanitize the path parameter if it coming from a web
    # page.  send_file(params[:path]) allows a malicious user to
    # download any file on your server.
    #
    # Options:
    # * <tt>:filename</tt> - suggests a filename for the browser to use.
    #   Defaults to File.basename(path).
    # * <tt>:type</tt> - specifies an HTTP content type.
    #   Defaults to 'application/octet-stream'.
    # * <tt>:disposition</tt> - specifies whether the file will be shown
    #   inline or downloaded. Valid values are 'inline' and 'attachment'
    #   (default). When set to nil, the Content-Disposition and
    #   Content-Transfer-Encoding headers are omitted entirely.
    # * <tt>:stream</tt> - whether to send the file to the user agent as it
    #   is read (true) or to read the entire file before sending (false).
    #   Defaults to true.
    # * <tt>:buffer_size</tt> - specifies size (in bytes) of the buffer used
    #   to stream the file. Defaults to 8192.
    # * <tt>:status</tt> - specifies the status code to send with the
    #   response. Defaults to '200 OK'.
    # * <tt>:last_modified</tt> - an optional RFC 2616 formatted date value
    #   (See Time#httpdate) indicating the last modified time of the file.
    #   If the request includes an If-Modified-Since header that matches this
    #   value exactly, a 304 Not Modified response is sent instead of the file.
    #   Defaults to the file's last modified time.
    #
    # The default Content-Type and Content-Disposition headers are
    # set to download arbitrary binary files in as many browsers as
    # possible.  IE versions 4, 5, 5.5, and 6 are all known to have
    # a variety of quirks (especially when downloading over SSL).
    #
    # Simple download:
    #   send_file '/path/to.zip'
    #
    # Show a JPEG in the browser:
    #   send_file '/path/to.jpeg',
    #     :type => 'image/jpeg',
    #     :disposition => 'inline'
    #
    # Show a 404 page in the browser:
    #   send_file '/path/to/404.html,
    #     :type => 'text/html; charset=utf-8',
    #     :status => 404
    #
    # Read about the other Content-* HTTP headers if you'd like to
    # provide the user with more information (such as Content-Description).
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.11
    #
    # Also be aware that the document may be cached by proxies and browsers.
    # The Pragma and Cache-Control headers declare how the file may be cached
    # by intermediaries.  They default to require clients to validate with
    # the server before releasing cached responses.  See
    # http://www.mnot.net/cache_docs/ for an overview of web caching and
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
    # for the Cache-Control header spec.
    def send_file(path, options = {}) #:doc:
      raise MissingFile, "Cannot read file #{path}" unless File.file?(path) and File.readable?(path)

      options[:length]   ||= File.size(path)
      options[:filename] ||= File.basename(path)
      options[:type] ||= Rack::File::MIME_TYPES[File.extname(options[:filename])[1..-1]] || 'text/plain'
      options[:last_modified] ||= File.mtime(path).httpdate
      options[:stream] = true unless options.key?(:stream)
      options[:buffer_size] ||= DEFAULT_SEND_FILE_OPTIONS[:buffer_size]
      send_file_headers! options

      if options[:stream]
        throw :halt, [options[:status] || 200, FileStreamer.new(path, options)]
      else
        File.open(path, 'rb') { |file| throw :halt, [options[:status] || 200, [file.read]] }
      end
    end

    # Send binary data to the user as a file download. May set content type,
    # apparent file name, and specify whether to show data inline or download
    # as an attachment.
    #
    # Options:
    # * <tt>:filename</tt> - Suggests a filename for the browser to use.
    # * <tt>:type</tt> - specifies an HTTP content type.
    #   Defaults to 'application/octet-stream'.
    # * <tt>:disposition</tt> - specifies whether the file will be shown inline
    #   or downloaded. Valid values are 'inline' and 'attachment' (default).
    # * <tt>:status</tt> - specifies the status code to send with the response.
    #   Defaults to '200 OK'.
    # * <tt>:last_modified</tt> - an optional RFC 2616 formatted date value (See
    #   Time#httpdate) indicating the last modified time of the response entity.
    #   If the request includes an If-Modified-Since header that matches this
    #   value exactly, a 304 Not Modified response is sent instead of the data.
    #
    # Generic data download:
    #   send_data buffer
    #
    # Download a dynamically-generated tarball:
    #   send_data generate_tgz('dir'), :filename => 'dir.tgz'
    #
    # Display an image Active Record in the browser:
    #   send_data image.data,
    #     :type => image.content_type,
    #     :disposition => 'inline'
    #
    # See +send_file+ for more information on HTTP Content-* headers and caching.
    def send_data(data, options = {}) #:doc:
      send_file_headers! options.merge(:length => data.size)
      throw :halt, [options[:status] || 200, [data]]
    end

  private

    def send_file_headers!(options)
      options = DEFAULT_SEND_FILE_OPTIONS.merge(options)
      [:length, :type, :disposition].each do |arg|
        raise ArgumentError, ":#{arg} option required" unless options.key?(arg)
      end

      # Send a "304 Not Modified" if the last_modified option is provided and
      # matches the If-Modified-Since request header value.
      if last_modified = options[:last_modified]
        header 'Last-Modified' => last_modified
        throw :halt, [ 304, '' ] if last_modified == request.env['HTTP_IF_MODIFIED_SINCE']
      end

      headers(
        'Content-Length'            => options[:length].to_s,
        'Content-Type'              => options[:type].strip  # fixes a problem with extra '\r' with some browsers
      )

      # Omit Content-Disposition and Content-Transfer-Encoding headers if
      # the :disposition option set to nil.
      if !options[:disposition].nil?
        disposition = options[:disposition].dup || 'attachment'
        disposition <<= %(; filename="#{options[:filename]}") if options[:filename]
        headers 'Content-Disposition' => disposition, 'Content-Transfer-Encoding' => 'binary'
      end

      # Fix a problem with IE 6.0 on opening downloaded files:
      # If Cache-Control: no-cache is set (which Rails does by default),
      # IE removes the file it just downloaded from its cache immediately
      # after it displays the "open/save" dialog, which means that if you
      # hit "open" the file isn't there anymore when the application that
      # is called for handling the download is run, so let's workaround that
      header('Cache-Control' => 'private') if headers['Cache-Control'] == 'no-cache'
    end
  end
end