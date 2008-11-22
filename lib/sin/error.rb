module Sin
  
  class Error

    attr_reader :type, :block, :options

    def initialize(type, options={}, &block)
      @type = type
      @block = block
      @options = options
    end

    def invoke(request)
      Result.new(block, options, code)
    end

    def code
      if type.respond_to?(:code)
        type.code
      else
        500
      end
    end

  end
  
end