module Sin
  class Event
    include Utils

    URI_CHAR = '[^/?:,&#\.]'.freeze unless defined?(URI_CHAR)
    PARAM = /(:(#{URI_CHAR}+)|\*)/.freeze unless defined?(PARAM)
    SPLAT = /(.*?)/
    attr_reader :path, :block, :param_keys, :pattern, :options

    def initialize(path, options = {}, &b)
      @path = URI.encode(path)
      @block = b
      @param_keys = []
      @options = options
      splats = 0
      regex = @path.to_s.gsub(PARAM) do |match|
        if match == "*"
          @param_keys << "_splat_#{splats}"
          splats += 1
          SPLAT.to_s
        else
          @param_keys << $2
          "(#{URI_CHAR}+)"
        end
      end

      @pattern = /^#{regex}$/
    end

    def invoke(request)
      params = {}
      if agent = options[:agent]
        return unless request.user_agent =~ agent
        params[:agent] = $~[1..-1]
      end
      if host = options[:host]
        return unless host === request.host
      end
      return unless pattern =~ request.path_info.squeeze('/')
      path_params = param_keys.zip($~.captures.map{|s| unescape(s) if s}).to_hash
      params.merge!(path_params)
      splats = params.select { |k, v| k =~ /^_splat_\d+$/ }.sort.map(&:last)
      unless splats.empty?
        params.delete_if { |k, v| k =~ /^_splat_\d+$/ }
        params["splat"] = splats
      end
      Result.new(block, params, 200)
    end

  end
end