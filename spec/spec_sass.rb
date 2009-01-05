require File.dirname(__FILE__) + '/helper'

describe "Sass" do

  describe "Templates (in general)" do

    it "are read from files if Symbols" do
      app do
        get '/from_file' do
          sass :foo, :views_directory => File.dirname(__FILE__) + "/views"
        end
      end

      get_it '/from_file'
      should.be.ok
      body.should.equal "#sass {\n  background_color: #FFF; }\n"

    end

    it "raise an error if template not found" do
      app do
        get '/' do
          sass :not_found
        end
      end

      lambda { get_it '/' }.should.raise(Errno::ENOENT)
    end

    it "ignore default layout file with .sass extension" do
      app do
        get '/' do
          sass :foo, :views_directory => File.dirname(__FILE__) + "/views/layout_test"
        end
      end

      get_it '/'
      should.be.ok
      body.should.equal "#sass {\n  background_color: #FFF; }\n"
    end

    it "ignore explicitly specified layout file" do
      app do
        get '/' do
          sass :foo, :layout => :layout, :views_directory => File.dirname(__FILE__) + "/views/layout_test"
        end
      end

      get_it '/'
      should.be.ok
      body.should.equal "#sass {\n  background_color: #FFF; }\n"
    end

  end

end
