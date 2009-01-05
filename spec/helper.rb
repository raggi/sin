# Disable test/unit and rspec from running, in case loaded by broken tools.
Test::Unit.run = false if defined?(Test::Unit)
Spec::run = false if defined?(Spec) && Spec::respond_to?(:run=)

# Setup a nice testing environment
$TESTING=true
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.uniq!

begin; require 'rubygems'; rescue LoadError; end

%w[bacon mocha].each { |r| require r }

# Bacon doesn't do any automagic, so lets tell it to!
Bacon.summary_on_exit

require File.expand_path(
  File.join(File.dirname(__FILE__), %w[.. lib sin]))

require 'sin/test/bacon'
