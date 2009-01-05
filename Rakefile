# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'sin'

task :default => 'spec:run'

PROJ.name = 'sin'
PROJ.authors = 'James Tucker'
PROJ.email = 'raggi@rubyforge.org'
PROJ.url = 'http://github.com/raggi/sin'
PROJ.rubyforge.name = 'sin'
PROJ.version = Sin.version

PROJ.exclude = %w(tmp$ bak$ ~$ CVS \.git \.hg \.svn ^pkg ^doc \.DS_Store
  \.cvs \.svn \.hgignore \.gitignore \.dotest \.swp$ ~$)

CLEAN.include 'pkg'
# EOF
