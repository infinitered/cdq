$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

require 'bundler'
require 'bundler/gem_tasks'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'CDQ'
  app.vendor_project('vendor/cdq/ext', :static)
end

if ARGV.join(' ') =~ /spec/
  Bundler.require :default, :spec
else
  Bundler.require
end

require 'cdq'
require 'motion-stump'
require 'ruby-xcdm'
require 'motion-yaml'

task :"build:simulator" => :"schema:build"
task :"build:simulator" => :"schema:build"
task :"build:simulator" => :"schema:build"
task :"build:simulator" => :"schema:build"
task :"build:simulator" => :"schema:build"
