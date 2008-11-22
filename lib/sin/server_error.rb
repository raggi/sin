module Sin
  class ServerError < RuntimeError
    def self.code ; 500 ; end
  end
end