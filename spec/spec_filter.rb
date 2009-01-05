require File.dirname(__FILE__) + '/helper'

describe "before filters" do

  before do
    app do; end
  end

  should "be executed in the order defined" do
    invoked = 0x0
    app.dsl.before { invoked = 0x01 }
    app.dsl.before { invoked |= 0x02 }
    app.dsl.get('/') { 'Hello World' }
    get_it '/'
    should.be.ok
    body.should.be == 'Hello World'
    invoked.should.be == 0x03
  end

  should "be capable of modifying the request" do
    app.dsl.get('/foo') { 'foo' }
    app.dsl.get('/bar') { 'bar' }
    app.dsl.before { request.path_info = '/bar' }
    get_it '/foo'
    should.be.ok
    body.should.be == 'bar'
  end

end
