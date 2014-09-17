
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
  # targeted query.  (This is also used internally for dedicated models.)
  #
  #   cdq(Author).where(:attribute).eq(1).limit(3)
  #
  # String: Finds an entity with the name provided in the string and returns a
  # targeted query.
  #
  #   cdq('Author').where(:attribute).eq(1).limit(3)
  #
  # Symbol: Returns an untargeted partial predicate.  This is useful for nested
  # queries, and for defining scopes.
  #
  #   Author.scope :singletons, cdq(:attribute).eq(1)
  #   Author.where( cdq(:attribute).eq(1).or.eq(3) ).and(:name).ne("Roger")
  #
  # CDQObject: returns the object itself (no-op).
  #
  # NSManagedObject: wraps the object in a CDQObjectProxy, which permits
  # cdq-style queries on the object's relationships.
  #
  #   emily_dickinson = Author.first
  #   cdq(emily_dickinson).articles.where(:page_count).lt(5).array
  #
  # Array: wraps the array in a CDQCollectionProxy, which lets you run queries
  # relative to the members of the collection.
  #
  #   emily_dickinson = Author.first
  #   edgar_allen_poe = Author.all[4]
  #   charles_dickens = Author.all[7]
  #   cdq([emily_dickinson, edgar_allen_poe, charles_dickens]).where(:avg_rating).eq(1)
  #
  def cdq(obj = nil)
    obj ||= self

    @@base_object ||= CDQObject.new

    case obj
    when Class
      if obj.isSubclassOfClass(NSManagedObject)
        entities = NSDictionary.dictionaryWithDictionary(
          @@base_object.models.current.entitiesByName)
        entity_name = obj.name.split("::").last
        # NOTE attempt to look up the entity
        entity_description =
          entities[entity_name] ||
          entities[obj.ancestors[1].name]
        if entity_description.nil?
          raise "Cannot find an entity named #{obj.name}"
        end
        CDQTargetedQuery.new(entity_description, obj)
      else
        @@base_object
      end
    when String
      entities = NSDictionary.dictionaryWithDictionary(
        @@base_object.models.current.entitiesByName)
      entity_description = entities[obj]
      target_class = NSClassFromString(entity_description.managedObjectClassName)
      if entity_description.nil?
        raise "Cannot find an entity named #{obj}"
      end
      CDQTargetedQuery.new(entity_description, target_class)
    when NSEntityDescription
      entity_description = obj
      target_class = NSClassFromString(entity_description.managedObjectClassName)
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
