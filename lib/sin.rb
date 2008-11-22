module Sin

  Dependencies = %w(time uri rack)

  Dependencies.each do |dep|
    require dep
  end

  Version = '0.1.0'

  # The base require path to your application or library.
  RequirePath = File.basename(__FILE__, File.extname(__FILE__))
  
  require File.join(RequirePath, 'core_ext')

  # Add file base-names to this array, and they will be auto-loaded based on 
  # the snake to camel case conversion of the name.
  Autoloads = %w(
  erb error event rendering_helpers request response_helpers static streaming
  utils haml sass builder event_context application result dsl server_error
  not_found result rackup
  )

  Autoloads.each do |lib|
    const_name = lib.split(/_/).map{ |s| s.capitalize }.join
    autoload const_name, File.join(RequirePath, lib)
  end

  # Returns the version string for the library.
  #
  def self.version
    Version
  end

end