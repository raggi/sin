module Sin
  module Rackup
    def sin(url = '/', options = {}, &blk)
      app = Application.new options

      if f = options.delete(:load)
        app.from_file f
      else
        app.from_code &blk
      end

      map url do
        run app
      end
    end
  end
end