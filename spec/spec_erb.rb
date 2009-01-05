require File.dirname(__FILE__) + '/helper'

describe "Erb" do

  describe "without layouts" do

    should "render" do
      app do
        get '/no_layout' do
          erb '<%= 1 + 1 %>'
        end
      end

      get_it '/no_layout'
      should.be.ok
      body.should == '2'

    end

    should "take an options hash with :locals set with a string" do
      app do
        get '/locals' do
          erb '<%= foo %>', :locals => {:foo => "Bar"}
        end
      end

      get_it '/locals'
      should.be.ok
      body.should == 'Bar'
    end

    should "take an options hash with :locals set with a complex object" do
      app do
        get '/locals-complex' do
          erb '<%= foo[0] %>', :locals => {:foo => ["foo", "bar", "baz"]}
        end
      end

      get_it '/locals-complex'
      should.be.ok
      body.should == 'foo'
    end
  end

  describe "with layouts" do

    it "can be inline" do
      app do
        layout do
          %Q{This is <%= yield %>!}
        end

        get '/lay' do
          erb 'Blake'
        end
      end

      get_it '/lay'
      should.be.ok
      body.should.equal 'This is Blake!'

    end

    it "can use named layouts" do
      app do
        layout :pretty do
          %Q{<h1><%= yield %></h1>}
        end

        get '/pretty' do
          erb 'Foo', :layout => :pretty
        end

        get '/not_pretty' do
          erb 'Bar'
        end
      end

      get_it '/pretty'
      body.should.equal '<h1>Foo</h1>'

      get_it '/not_pretty'
      body.should.equal 'Bar'

    end

    should "can be read from a file if they're not inlined" do
      app do
        get '/foo' do
          @title = 'Welcome to the Hello Program'
          erb 'Blake', :layout => :foo_layout,
                       :views_directory => File.dirname(__FILE__) + "/views"
        end
      end

      get_it '/foo'
      body.should.equal "Welcome to the Hello Program\nHi Blake\n"

    end

  end

  describe "Templates (in general)" do

    it "are read from files if Symbols" do
      app do
        get '/from_file' do
          @name = 'Alena'
          erb :foo, :views_directory => File.dirname(__FILE__) + "/views"
        end
      end

      get_it '/from_file'

      body.should.equal 'You rock Alena!'

    end

    it "use layout.ext by default if available" do
      app do
        get '/layout_from_file' do
          erb :foo, :views_directory => File.dirname(__FILE__) + "/views/layout_test"
        end
      end

      get_it '/layout_from_file'
      should.be.ok
      body.should.equal "x This is foo! x \n"

    end

  end

end
