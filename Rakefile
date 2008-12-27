# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  load 'tasks/setup.rb'
end

ensure_in_path 'lib'
require 'lockdown'

task :default => 'spec:run'

PROJ.name = 'lockdown'
PROJ.authors = 'Andrew Stone'
PROJ.email = 'andy@stonean.com'
PROJ.url = 'http://stonean.com/wiki/lockdown'
PROJ.version = Lockdown::VERSION
PROJ.rubyforge.name = 'lockdown'

PROJ.spec.opts << '--color'

# EOF
