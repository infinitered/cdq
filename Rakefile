$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'CDQ'
  app.files = %w{
    motion/cdq.rb
    motion/cdq/object.rb
    motion/cdq/context.rb
    motion/cdq/model.rb
    motion/cdq/partial_predicate.rb
    motion/cdq/query.rb
    motion/cdq/store.rb
    motion/cdq/targeted_query.rb
    motion/cdq/managed_object.rb

    app/test_models.rb
    app/app_delegate.rb
  }
  app.frameworks += %w{ CoreData }
end

require 'motion-stump'
require 'ruby-xcdm'
