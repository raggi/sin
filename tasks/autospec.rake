# Poor mans autotest, for when you absolutely positively, just need an autotest.
# N.B. Uses a runner under test/ or spec/, so you can customize the runtime.
# Thanks to manveru for this!
desc "Run specs every time a file changes in lib or spec"
task :autospec do
  rb = Gem.ruby rescue nil
  rb ||= (require 'rbconfig'; File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name']))
  command = 'spec/runner' if test ?e, 'spec/runner'
  command ||= 'test/runner' if test ?e, 'test/runner'
  files = Dir.glob('{lib,spec,test}/**/*.rb')
  mtimes = {}
  sigtrap = proc { puts "\rDo that again, I dare you!"; trap(:INT){ exit 0 }; sleep 0.8; trap(:INT, &sigtrap) }
  trap(:INT, &sigtrap)
  system "#{rb} -I#{GSpec.require_path} #{command}"
  while file = files.shift
    begin
      mtime = File.mtime(file)
      mtimes[file] ||= mtime
      if mtime > mtimes[file]
        files = Dir.glob('{lib,spec,test}/**/*.rb') - [file] # refresh the file list.
        puts
        system "#{rb} -I#{GSpec.require_path} #{command} #{file}"
        puts
      end
      mtimes[file] = mtime
      files << file
    rescue Exception
      retry
    end
    # print "\rChecking: #{file.ljust((ENV['COLUMNS']||80)-11)}";$stdout.flush
    sleep 0.2
  end
end