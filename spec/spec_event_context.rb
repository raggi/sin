require File.dirname(__FILE__) + '/helper'

describe "EventContext" do

  it "DSLified setters" do
    app do; end
    cx = Sin::EventContext.new(app, Rack::Request.new({}), Rack::Response.new, {})
    should.not.raise(ArgumentError) do
      cx.status 404
    end

  end

end

