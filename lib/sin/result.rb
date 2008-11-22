module Sin
  class Result
    attr_accessor :block, :params, :status
    def initialize(block, params, status)
      @block, @params, @status = block, params, status
    end
  end
end