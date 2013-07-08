
module CDQ

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
  #   class MyEntity < CDQ::CDQManagedObject
  #     scope :last_week, where(:created_at).ge(date.delta(weeks: -2)).and.lt(date.delta(weeks: -1))
  #   end
  #
  #   MyEntity.last_week.where(:created_by => john)
  #
  class CDQManagedObject < NSManagedObject

    extend CDQ
    include CDQ

    class << self

      # Shortcut to look up the entity description for this class
      #
      def entity_description
        cdq.models.current.entitiesByName[name]
      end

      # Creates a CDQ scope, but also defines a method on the class that returns the 
      # query directly.
      #
      def scope(name, query)
        cdq.scope name, query
        self.class.send(:define_method, name) do |*args|
          query
        end
      end

      # Pass any unknown methods on to cdq. 
      #
      def method_missing(name, *args)
        cdq.send(name, *args)
      end

    end

    # Register this object for destruction with the current context.  Will not
    # actually be removed until the context is saved.
    #
    def destroy
      managedObjectContext.deleteObject(self)
    end

  end
  
end
