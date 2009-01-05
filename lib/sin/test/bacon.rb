require File.dirname(__FILE__) + '/methods'
require 'rack'
require 'bacon'

Bacon::Context.send(:include, Sin::Test::Methods)

Bacon.summary_on_exit

Sin::Application.default_options.merge!(
  :env => :test,
  :raise_errors => true,
  :logging => false
)

