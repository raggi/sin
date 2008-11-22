module Sin
  class Static
    include Utils

    def initialize(app)
      @app = app
    end

    def invoke(request)
      path = @app.options[:public] + unescape(request.path_info)
      return unless File.file?(path)
      block = Proc.new { send_file path, :disposition => nil }
      Result.new(block, {}, 200)
    end
  end
end