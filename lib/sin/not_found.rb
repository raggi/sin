module Sin
  class NotFound < RuntimeError
    def self.code ; 404 ; end
  end
end