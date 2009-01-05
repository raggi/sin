require File.dirname(__FILE__) + '/helper'

class FooError < RuntimeError; end

describe "Mapped errors" do

  before do
    app do; end
    app.options[:raise_errors] = false
  end

  it "are rescued and run in context" do
    app.dsl.eval do
      error FooError do
        'MAPPED ERROR!'
      end

      get '/' do
        raise FooError
      end
    end

    get_it '/'

    should.be.server_error
    body.should.equal 'MAPPED ERROR!'

  end

  it "renders empty if no each method on result" do
    app.dsl.eval do
      error FooError do
        nil
      end

      get '/' do
        raise FooError
      end
    end

    get_it '/'

    should.be.server_error
    body.should.be.empty

  end

  it "doesn't override status if set" do
    app.dsl.eval do
      error FooError do
        status(200)
      end

      get '/' do
        raise FooError
      end
    end

    get_it '/'

    should.be.ok

  end

  it "raises errors when the raise_errors option is set" do
    app.options[:raise_errors] = true
    app.dsl.eval do
      error FooError do
      end
      get '/' do
        raise FooError
      end
    end
    should.raise(FooError) { get_it('/') }
  end

end
