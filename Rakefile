$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

require 'bundler'

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

task :"build:simulator" => :"schema:build"
