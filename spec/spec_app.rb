require File.dirname(__FILE__) + '/helper'

describe "Sin" do
  
  should "not pollute (main) with DSL methods" do
    o = Object.new
    # basically, see a DHH presentation for what I think about the 'old' style
    # :-P
    (Sin::Dsl.instance_methods - Class.instance_methods).each do |method|
      o.methods.should.not.include(method)
    end
  end
    
  should "handle the result of nil" do
    app do
      get '/' do
        nil
      end
    end
    get_it '/'
    should.be.ok
    body.should == ''
  end
  
  should "handles events" do
    app do
      get '/:name' do
        'Hello ' + params["name"]
      end
    end
    get_it '/Blake'
    should.be.ok
    body.should.equal 'Hello Blake'
  end
  
  should "handles splats" do
    app do
      get '/hi/*' do
        params["splat"].kind_of?(Array).should.equal true
        params["splat"].first
      end
    end

    get_it '/hi/Blake'

    should.be.ok
    body.should.equal 'Blake'
  end


  should "handles multiple splats" do
    app do
      get '/say/*/to/*' do
        params["splat"].join(' ')
      end
    end
    get_it '/say/hello/to/world'

    should.be.ok
    body.should.equal 'hello world'
  end

  should "allow empty splats" do
    app do
      get '/say/*/to*/*' do
        params["splat"].join(' ')
      end
    end

    get_it '/say/hello/to/world'

    should.be.ok
    body.should.equal 'hello  world' # second splat is empty

    get_it '/say/hello/tomy/world'

    should.be.ok
    body.should.equal 'hello my world'
  end

  should "gives access to underlying response header Hash" do
    app do
      get '/' do
        header['X-Test'] = 'Is this thing on?'
        headers 'X-Test2' => 'Foo', 'X-Test3' => 'Bar'
        ''
      end
    end

    get_it '/'
    should.be.ok
    headers.should.include 'X-Test'
    headers['X-Test'].should.equal 'Is this thing on?'
    headers.should.include 'X-Test3'
    headers['X-Test3'].should.equal 'Bar'
  end

  should "follows redirects" do
    app do
      get '/' do
        redirect '/blake'
      end

      get '/blake' do
        'Mizerany'
      end
    end

    get_it '/'
    should.be.redirection
    body.should.equal ''

    follow!
    should.be.ok
    body.should.equal 'Mizerany'
  end

  should "renders a body with a redirect" do
    Sin::EventContext.any_instance.expects(:foo).returns('blah')
    app do
      get "/" do
        redirect 'foo', :foo
      end
    end
    get_it '/'
    should.be.redirection
    headers['Location'].should.equal 'foo'
    body.should.equal 'blah'
  end

  should "redirects permanently with 301 status code" do
    app do
      get "/" do
        redirect 'foo', 301
      end
    end
    get_it '/'
    should.be.redirection
    headers['Location'].should.equal 'foo'
    status.should.equal 301
    body.should.be.empty
  end

  should "stop sets content and ends event" do

    Sin::EventContext.any_instance.expects(:foo).never
    app do
      get '/set_body' do
        stop 'Hello!'
        stop 'World!'
        foo
      end
    end

    get_it '/set_body'

    should.be.ok
    body.should.equal 'Hello!'

  end

  should "should set status then call helper with a var" do
    Sin::EventContext.any_instance.expects(:foo).once.with(1).returns('bah!')
    app do
      get '/set_body' do
        stop [404, [:foo, 1]]
      end
    end

    get_it '/set_body'

    should.be.not_found
    body.should.equal 'bah!'

  end

  should "should easily set response Content-Type" do
    app do
      get '/foo.html' do
        content_type 'text/html', :charset => 'utf-8'
        "<h1>Hello, World</h1>"
      end
    end

    get_it '/foo.html'
    should.be.ok
    headers['Content-Type'].should.equal 'text/html;charset=utf-8'
    body.should.equal '<h1>Hello, World</h1>'

    app do
      get '/foo_test.xml' do
        content_type :xml
        "<feed></feed>"
      end
    end

    get_it '/foo_test.xml'
    should.be.ok
    headers['Content-Type'].should.equal 'application/xml'
    body.should.equal '<feed></feed>'
  end

  should "supports conditional GETs with last_modified" do
    modified_at = Time.now
    app do
      get '/maybe' do
        last_modified modified_at
        'response body, maybe'
      end
    end

    get_it '/maybe'
    should.be.ok
    body.should.equal 'response body, maybe'

    get_it '/maybe', :env => { 'HTTP_IF_MODIFIED_SINCE' => modified_at.httpdate }
    status.should.equal 304
    body.should.equal ''
  end

  should "supports conditional GETs with entity_tag" do
    app do
      get '/strong' do
        entity_tag 'FOO'
        'foo response'
      end
    end

    get_it '/strong'
    should.be.ok
    body.should.equal 'foo response'

    get_it '/strong', {},
      'HTTP_IF_NONE_MATCH' => '"BAR"'
    should.be.ok
    body.should.equal 'foo response'

    get_it '/strong', {},
      'HTTP_IF_NONE_MATCH' => '"FOO"'
    status.should.equal 304
    body.should.equal ''

    get_it '/strong', {},
      'HTTP_IF_NONE_MATCH' => '"BAR", *'
    status.should.equal 304
    body.should.equal ''
  end

  should "delegates HEAD requests to GET handlers" do
    app do
      get '/invisible' do
        "I am invisible to the world"
      end
    end

    head_it '/invisible'
    should.be.ok
    body.should.not.equal "I am invisible to the world"
    body.should.equal ''
  end


  should "supports PUT" do
    app do
      put '/' do
        'puted'
      end
    end
    put_it '/'
    body.should.eql('puted')
  end

  should "rewrites POSTs with _method param to PUT" do
    app do
      put '/' do
        'puted'
      end
    end
    post_it '/', :_method => 'PUT'
    body.should.eql('puted')
  end

  # Some Ajax libraries downcase the _method parameter value. Make
  # sure we can handle that.
  should "rewrites POSTs with lowercase _method param to PUT" do
    app do
      put '/' do
        'puted'
      end
    end
    post_it '/', :_method => 'put'
    body.should.equal 'puted'
  end

  # Ignore any _method parameters specified in GET requests or on the query string in POST requests.
  should "does not rewrite GETs with _method param to PUT" do
    app do
      get '/' do
        'getted'
      end
    end
    get_it '/', :_method => 'put'
    should.be.ok
    body.should.equal 'getted'
  end

  should "ignores _method query string parameter on non-POST requests" do
    app do
      post '/' do
        'posted'
      end
      put '/' do
        'booo'
      end
    end
    post_it "/?_method=PUT"
    should.be.ok
    body.should.equal 'posted'
  end

  should "does not read body if content type is not url encoded" do
    app do
      post '/foo.xml' do
        request.env['CONTENT_TYPE'].should.be == 'application/xml'
        request.content_type.should.be == 'application/xml'
        request.body.read
      end
    end

    post_it '/foo.xml', '<foo></foo>', :content_type => 'application/xml'
    @response.should.be.ok
    @response.body.should.be == '<foo></foo>'
  end

end