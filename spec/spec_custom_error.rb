require File.dirname(__FILE__) + '/helper'

describe "Custom Errors" do

  should "override the default 404" do
    app do; end

    get_it '/'
    should.be.not_found
    body.should.equal '<h1>Not Found</h1>'

    app do
      error Sin::NotFound do
        'Custom 404'
      end
    end

    get_it '/'
    should.be.not_found
    body.should.equal 'Custom 404'

  end

  should "override the default 500" do
    code = proc do
      get '/' do
        raise 'asdf'
      end
    end
    app &code
    app.options[:raise_errors] = false
    
    get_it '/'
    status.should.equal 500
    body.should.equal '<h1>Internal Server Error</h1>'

    app do
      instance_eval &code

      error do
        'Custom 500 for ' + request.env['sin.error'].message
      end
    end
    app.options[:raise_errors] = false

    get_it '/'

    get_it '/'
    status.should.equal 500
    body.should.equal 'Custom 500 for asdf'
  end

  class UnmappedError < RuntimeError; end

  should "bring unmapped error back to the top" do
    app do
      get '/' do
        raise UnmappedError, 'test'
      end
    end

    should.raise(UnmappedError) do
      get_it '/'
    end
  end

end
