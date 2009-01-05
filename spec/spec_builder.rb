require File.dirname(__FILE__) + '/helper'

describe "Builder" do

  describe "without layouts" do

    should "render" do
      app do
        get '/no_layout' do
          builder 'xml.instruct!'
        end
      end

      get_it '/no_layout'
      should.be.ok
      body.should == %(<?xml version="1.0" encoding="UTF-8"?>\n)

    end

    should "render inline block" do
      app do
        get '/no_layout_and_inlined' do
          @name = "Frank & Mary"
          builder do |xml|
            xml.couple @name
          end
        end
      end

      get_it '/no_layout_and_inlined'
      should.be.ok
      body.should == %(<couple>Frank &amp; Mary</couple>\n)

    end

  end



  describe "Templates (in general)" do

    should "read from files if Symbols" do
      app do
        get '/from_file' do
          @name = 'Blue'
          builder :foo, :views_directory => File.dirname(__FILE__) + "/views"
        end
      end

      get_it '/from_file'
      should.be.ok
      body.should.equal %(<exclaim>You rock Blue!</exclaim>\n)

    end

    should "use layout.ext by default if available" do
      app do
        get '/' do
          builder :foo, :views_directory => File.dirname(__FILE__) + "/views/layout_test"
        end
      end

      get_it '/'
      should.be.ok
      body.should.equal "<layout>\n<this>is foo!</this>\n</layout>\n"

    end

    it "can render without layout" do
      app do
        get '/' do
          builder :no_layout, :views_directory => File.dirname(__FILE__) + "/views/no_layout"
        end
      end

      get_it '/'
      should.be.ok
      body.should.equal "<foo>No Layout!</foo>\n"

    end

    should "raise error if template not found" do
      app do
        get '/' do
          builder :not_found
        end
      end

      lambda { get_it '/' }.should.raise(Errno::ENOENT)

    end

  end

end
