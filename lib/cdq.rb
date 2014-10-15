
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
  if app.respond_to?(:xcdm)
    cdqfile = File.join(app.project_dir, 'resources/cdq.yml')
    if File.exists?(cdqfile)
      hash = YAML.load(File.read(cdqfile))
      if hash
        app.xcdm.name = hash['model_name'] || hash['name']
      end
    end
  end
end
