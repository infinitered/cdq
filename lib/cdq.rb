
unless defined?(Motion::Project::App)
  raise "This must be required from within a RubyMotion Rakefile"
end

require 'ruby-xcdm'
require 'motion-yaml'

ENV['COLUMNS'] ||= `tput cols`.strip

Motion::Project::App.setup do |app|
  parent = File.join(File.dirname(__FILE__), '..')
  app.files.unshift(Dir.glob(File.join(parent, "motion/cdq/**/*.rb")))
  app.files.unshift(Dir.glob(File.join(parent, "motion/*.rb")))
  app.frameworks += %w{ CoreData }
  app.vendor_project(File.join(parent, 'vendor/cdq/ext'), :static)
end
