
module CDQ

  class CDQObject; end
  class CDQQuery < CDQObject; end
  class CDQPartialPredicate < CDQObject; end
  class CDQTargetedQuery < CDQQuery; end

  extend self

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

  def self.pollute(klass)
  end

end


class UIResponder #:nodoc: all
  include CDQ
end

class TopLevel #:nodoc: all
  include CDQ
end
