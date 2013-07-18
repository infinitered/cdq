
# CDQ Extensions for your custom entity objects.  This is mostly convenience
# and syntactic sugar -- you can access every feature using the cdq(Class).<em>method</em>
# syntax, but this enables the nicer-looking and more convenient Class.<em>method</em> style.
# Any method availble on cdq(Class) is now available directly on Class.
#
# If there is a conflict between a CDQ method and one of yours, or one of Core Data's,
# your code will always win.  In that case you can get at the CDQ method by calling
# Class.cdq.<em>method</em>.
#
# Examples:
# 
#   MyEntity.where(:name).eq("John").limit(2)
#   MyEntity.first
#   MyEntity.create(name: "John")
#   MyEntity.sort_by(:title)[4]
#
#   class MyEntity < CDQManagedObject
#     scope :last_week, where(:created_at).ge(date.delta(weeks: -2)).and.lt(date.delta(weeks: -1))
#   end
#
#   MyEntity.last_week.where(:created_by => john)
#
class CDQManagedObject < CoreDataQueryManagedObjectBase

  extend CDQ
  include CDQ

  class << self

    def inherited(klass) #:nodoc:
      cdq(klass).entity_description.relationshipsByName.each do |name, rdesc|
        if rdesc.isToMany
          klass.defineRelationshipMethod(name)
        end
      end
    end

    # Shortcut to look up the entity description for this class
    #
    def entity_description
      cdq.models.current.entitiesByName[name]
    end

    # Creates a CDQ scope, but also defines a method on the class that returns the 
    # query directly.
    #
    def scope(name, query = nil, &block)
      cdq.scope(name, query, &block)
      if query
        self.class.send(:define_method, name) do 
          query
        end
      else
        self.class.send(:define_method, name) do |*args|
          block.call(*args)
        end
      end
    end

    def new(*args)
      cdq.new(*args)
    end

    # Pass any unknown methods on to cdq. 
    #
    def method_missing(name, *args, &block)
      cdq.send(name, *args, &block)
    end

    def responds_to?(name)
      super || cdq.respond_to?(name)
    end

  end

  # Register this object for destruction with the current context.  Will not
  # actually be removed until the context is saved.
  #
  def destroy
    managedObjectContext.deleteObject(self)
  end

  protected

  # Called from method that's dynamically added from
  # +[CoreDataManagedObjectBase defineRelationshipMethod:]
  def relationshipByName(name)
    willAccessValueForKey(name)
    set = CDQRelationshipQuery.extend_set(primitiveValueForKey(name), self, name)
    didAccessValueForKey(name)
    set
  end
end
