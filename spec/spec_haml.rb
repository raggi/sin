require File.dirname(__FILE__) + '/helper'

describe "Haml" do

  describe "without layouts" do

    should "render" do
      app do
        get '/no_layout' do
          haml '== #{1+1}'
        end
      end

      get_it '/no_layout'
      should.be.ok
      body.should == "2\n"

    end
  end

  describe "with layouts" do

    it "can be inline" do
      app do
        layout do
          '== This is #{yield}!'
        end

        get '/lay' do
          haml 'Blake'
        end
      end

      get_it '/lay'
      should.be.ok
      body.should.equal "This is Blake\n!\n"

    end

    it "can use named layouts" do
      app do
        layout :pretty do
          '%h1== #{yield}'
        end

        get '/pretty' do
          haml 'Foo', :layout => :pretty
        end

        get '/not_pretty' do
          haml 'Bar'
        end
      end

      get_it '/pretty'
      body.should.equal "<h1>Foo</h1>\n"

      get_it '/not_pretty'
      body.should.equal "Bar\n"

    end

    it "can be read from a file if they're not inlined" do
      app do
        get '/foo' do
          @title = 'Welcome to the Hello Program'
          haml 'Blake', :layout => :foo_layout,
                        :views_directory => File.dirname(__FILE__) + "/views"
        end
      end

      get_it '/foo'
      body.should.equal "Welcome to the Hello Program\nHi Blake\n"

    end

    it "can be read from file and layout from text" do
      app do
        get '/foo' do
          haml 'Test', :layout => '== Foo #{yield}'
        end
      end

      get_it '/foo'

      body.should.equal "Foo Test\n"
    end

  end

  describe "Templates (in general)" do

    it "are read from files if Symbols" do
      app do
        get '/from_file' do
          @name = 'Alena'
          haml :foo, :views_directory => File.dirname(__FILE__) + "/views"
        end
      end

      get_it '/from_file'

      body.should.equal "You rock Alena!\n"

    end

    it "use layout.ext by default if available" do
      app do
        get '/' do
          haml :foo, :views_directory => File.dirname(__FILE__) + "/views/layout_test"
        end
      end

      get_it '/'
      should.be.ok
      body.should.equal "x This is foo!\n x\n"

    end

    it "renders without layout" do
      app do
        get '/' do
          haml :no_layout, :views_directory => File.dirname(__FILE__) + "/views/no_layout"
        end
      end

      get_it '/'
      should.be.ok
      body.should.equal "<h1>No Layout!</h1>\n"

    end

    it "can render with no layout" do
      app do
        layout do
          "X\n= yield\nX"
        end

        get '/' do
          haml 'blake', :layout => false
        end
      end

      get_it '/'

      body.should.equal "blake\n"
    end

    it "raises error if template not found" do
      app do
        get '/' do
          haml :not_found
        end
      end

      lambda { get_it '/' }.should.raise(Errno::ENOENT)
    end

    it "use layout.ext by default if available" do
      app do
        template :foo do
          'asdf'
        end

        get '/' do
          haml :foo, :layout => false,
                     :views_directory => File.dirname(__FILE__) + "/views/layout_test"
        end
      end
      get_it '/'
      should.be.ok
      body.should.equal "asdf\n"

    end

  end

  describe 'Options passed to the HAML interpreter' do
    def fake_render
      o = Object.new
      def o.render *args; 'foo'; end
      o
    end

    it 'are empty be default' do
      app do
        get '/' do
          haml 'foo'
        end
      end
      
      Haml::Engine.expects(:new).with('foo', {}).returns(fake_render)

      get_it '/'
      should.be.ok

    end

    it 'can be configured by passing :options to haml' do
      app do
        get '/' do
          haml 'foo', :options => {:format => :html4}
        end
      end

      Haml::Engine.expects(:new).with('foo', {:format => :html4}).returns(fake_render)

      get_it '/'
      should.be.ok

    end

    it 'can be configured using set_option :haml' do
      app do
        configure do
          set_option :haml, :format       => :html4,
                            :escape_html  => true
        end

        get '/' do
          haml 'foo'
        end
      end
      Haml::Engine.expects(:new).with('foo', {:format => :html4,
        :escape_html => true}).returns(fake_render)

      get_it '/'
      should.be.ok

    end

  end

end
