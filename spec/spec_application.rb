require File.dirname(__FILE__) + '/helper'

require 'uri'

class TesterWithEach
  def each
    yield 'foo'
    yield 'bar'
    yield 'baz'
  end
end

describe "Looking up a request" do

  should "return what's at the end" do
    block = Proc.new { 'Hello' }
    app do
      get '/', &block
    end

    result = app.lookup(
      Rack::Request.new(
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/'
      )
    )

    result.should.not.be.nil
    result.block.should.be block
  end

  should "take params in path" do
    block = Proc.new { 'Hello' }
    app do
      get '/:foo', &block
    end

    result = app.lookup(
      Rack::Request.new(
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/bar'
      )
    )

    result.should.not.be.nil
    result.block.should.be block
    result.params.should.equal "foo" => 'bar'
  end

end

describe "An app returns" do

  it "a 404 if no events found" do
    app do; end
    request = Rack::MockRequest.new(app)
    get_it '/'
    should.be.not_found
    body.should.equal '<h1>Not Found</h1>'
  end

  it "a 200 if success" do
    app do
      get '/' do
        'Hello World'
      end
    end
    get_it '/'
    should.be.ok
    body.should.equal 'Hello World'
  end

  it "an objects result from each if it has it" do
    app do
      get '/' do
        TesterWithEach.new
      end
    end

    get_it '/'
    should.be.ok
    body.should.equal 'foobarbaz'

  end

  should "the body set if set before the last" do
    app do
      get '/' do
        body 'Blake'
        'Mizerany'
      end
    end

    get_it '/'
    should.be.ok
    body.should.equal 'Blake'

  end

end

describe "Dsl#configure blocks" do
  
  before do
    @dsl = Sin::Dsl.new(app do; end)
  end

  should "run when no environment specified" do
    ref = false
    @dsl.configure { ref = true }
    ref.should.equal true
  end

  should "run when matching environment specified" do
    ref = false
    @dsl.configure(:test) { ref = true }
    ref.should.equal true
  end

  should "do not run when no matching environment specified" do
    ref = false
    @dsl.configure(:foo) { ref = true; flunk "block should not have been executed" }
    @dsl.configure(:development, :production, :foo) { ref = true; flunk "block should not have been executed" }
    ref.should.be.false
  end

  should "accept multiple environments" do
    ref = false
    @dsl.configure(:foo, :test, :bar) { ref = true }
    ref.should.equal true
  end

end

describe "Default Application Configuration" do
  before do
    app do; end
  end

  should "includes 404 and 500 error handlers" do
    app.errors.should.include(Sin::ServerError)
    app.errors[Sin::ServerError].should.not.be.nil
    app.errors.should.include(Sin::NotFound)
    app.errors[Sin::NotFound].should.not.be.nil
  end

  should "includes Static event" do
    app.events[:get].any? { |e| Sin::Static === e }.should.be.true
  end

end

describe "Events in an app" do

  should "evaluate in a clean context" do
    app do
      helpers do
        def foo
          'foo'
        end
      end

      get '/foo' do
        foo
      end
    end

    get_it '/foo'
    should.be.ok
    body.should.equal 'foo'
  end

  should "get access to request, response, and params" do
    app do
      get '/:foo' do
        params["foo"] + params["bar"]
      end
    end

    get_it '/foo?bar=baz'
    should.be.ok
    body.should.equal 'foobaz'
  end

  should "can filters by agent" do
    app do
      get '/', :agent => /Windows/ do
        request.env['HTTP_USER_AGENT']
      end
    end

    get_it '/', :env => { :agent => 'Windows' }
    should.be.ok
    body.should.equal 'Windows'

    get_it '/', :env => { :agent => 'Mac' }
    should.not.be.ok

  end

  should "can use regex to get parts of user-agent" do
    app do
      get '/', :agent => /Windows (NT)/ do
        params[:agent].first
      end
    end

    get_it '/', :env => { :agent => 'Windows NT' }

    body.should.equal 'NT'

  end

  should "can deal with spaces in paths" do

    path = '/path with spaces'
    app do
      get path do
        "Look ma, a path with spaces!"
      end
    end

    get_it URI.encode(path)

    body.should.equal "Look ma, a path with spaces!"
  end

  should "route based on host" do
    app do
      get '/' do
        'asdf'
      end
    end

    get_it '/'
    should.be.ok
    body.should.eql 'asdf'

    app do
      get '/foo', :host => 'foo.sinatrarb.com' do
        'in foo!'
      end

      get '/foo', :host => 'bar.sinatrarb.com'  do
        'in bar!'
      end
    end

    get_it '/foo', {}, 'HTTP_HOST' => 'foo.sinatrarb.com'
    should.be.ok
    body.should.eql 'in foo!'

    get_it '/foo', {}, 'HTTP_HOST' => 'bar.sinatrarb.com'
    should.be.ok
    body.should.eql 'in bar!'

    get_it '/foo'
    should.be.not_found

  end

end


describe "Options in an app" do

  before do
    app do; end
  end

  should "can be set singly on app" do
    app.dsl.set :foo, 1234
    app.options[:foo].should.equal 1234
  end

  should "can be set singly from top-level" do
    app.dsl.set_option :foo, 1234
    app.options[:foo].should.equal 1234
  end

  should "can be set multiply on app" do
    app.options[:foo].should.be.nil
    app.dsl.set :foo => 1234,
      :bar => 'hello, world'
    app.options[:foo].should.equal 1234
    app.options[:bar].should.equal 'hello, world'
  end

  should "can be set multiply from top-level" do
    app.options[:foo].should.be.nil
    app.dsl.set_options :foo => 1234,
      :bar => 'hello, world'
    app.options[:foo].should.equal 1234
    app.options[:bar].should.equal 'hello, world'
  end

  should "can be enabled on app" do
    app.options[:foo].should.be.nil
    app.dsl.enable :sessions, :foo, :bar
    app.options[:sessions].should.equal true
    app.options[:foo].should.equal true
    app.options[:bar].should.equal true
  end

  should "can be enabled from top-level" do
    app.options[:foo].should.be.nil
    app.dsl.enable :sessions, :foo, :bar
    app.options[:sessions].should.equal true
    app.options[:foo].should.equal true
    app.options[:bar].should.equal true
  end

  should "can be disabled on app" do
    app.options[:foo].should.be.nil
    app.dsl.disable :sessions, :foo, :bar
    app.options[:sessions].should.equal false
    app.options[:foo].should.equal false
    app.options[:bar].should.equal false
  end

  should "can be enabled from top-level" do
    app.options[:foo].should.be.nil
    app.dsl.disable :sessions, :foo, :bar
    app.options[:sessions].should.equal false
    app.options[:foo].should.equal false
    app.options[:bar].should.equal false
  end

end
