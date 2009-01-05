require 'test/unit'
require File.dirname(__FILE__) + '/methods'

Test::Unit::TestCase.send(:include, Sin::Test::Methods)

Sin::Application.default_options.merge!(
  :env => :test,
  :raise_errors => true,
  :logging => false
)
