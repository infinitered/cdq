$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'CDQ'
  app.files  = Dir['motion/**/*.rb'] + Dir['app/**/*.rb']
  app.frameworks += %w{ CoreData }
end

require 'motion-stump'
require 'ruby-xcdm'
