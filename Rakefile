$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'CDQ'
  app.files  = Dir['motion/**/*.rb'] + Dir['app/**/*.rb']
  app.frameworks += %w{ CoreData }

  app.vendor_project('vendor/cdq/ext', :static)
end

require 'motion-stump'
require 'ruby-xcdm'
