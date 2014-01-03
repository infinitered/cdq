
module CDQ

  class CDQObject; end
  class CDQQuery < CDQObject; end
  class CDQPartialPredicate < CDQObject; end
  class CDQTargetedQuery < CDQQuery; end

  extend self

  # The master method that will lift a variety of arguments into the CDQ
  # ecosystem.  What it returns depends on the type of the argument passed:
  #
  # Class: Finds an entity with the same name as the class and returns a
  # targeted query.
  #
  # String: Finds an entity with the name provided in the string and returns a
  # targeted query.
  #
  # Symbol: Returns an untargeted partial predicate.  This is useful for nested
  # queries, and for defining scopes.
  #
  # CDQObject: returns the object itself (no-op).
  #
  # NSManagedObject: wraps the object in a CDQObjectProxy, which permits
  # cdq-style queries on the object's relationships.
  #
  # Array: wraps the array in a CDQCollectionProxy, which lets you run queries
  # relative to the members of the collection.
  #
  def cdq(obj = nil)
    obj ||= self

    @@base_object ||= CDQObject.new

    case obj
    when Class
      if obj.isSubclassOfClass(NSManagedObject)
        entity_description = @@base_object.models.current.entitiesByName[obj.name]
        if entity_description.nil?
          raise "Cannot find an entity named #{obj.name}"
        end
        CDQTargetedQuery.new(entity_description, obj)
      else
        @@base_object
      end
    when String
      entity_description = @@base_object.models.current.entitiesByName[obj]
      target_class = NSClassFromString(entity_description.managedObjectClassName)
      if entity_description.nil?
        raise "Cannot find an entity named #{obj}"
      end
      CDQTargetedQuery.new(entity_description, target_class)
    when Symbol
      CDQPartialPredicate.new(obj, CDQQuery.new)
    when CDQObject
      obj
    when NSManagedObject
      CDQObjectProxy.new(obj)
    when Array
      if obj.first.class.isSubclassOfClass(NSManagedObject)
        CDQCollectionProxy.new(obj, obj.first.entity)
      else
        @@base_object
      end
    else
      @@base_object
    end
  end

end


# @private
class UIResponder
  include CDQ
end

# @private
class TopLevel
  include CDQ
end
