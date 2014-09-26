
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

    # Creates a CDQ scope, but also defines a method on the class that returns the
    # query directly.
    #
    def scope(name, query = nil, &block)
      cdq.scope(name, query, &block)
      if query
        self.class.send(:define_method, name) do
          where(query)
        end
      else
        self.class.send(:define_method, name) do |*args|
          where(block.call(*args))
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

    def respond_to?(name)
      if cdq_initialized?
        super(name) || cdq.respond_to?(name)
      else
        super(name)
      end
    end

    def destroy_all
      self.all.array.each do |instance|
        instance.destroy
      end
    end

    def destroy_all!
      destroy_all
      cdq.save
    end

    def attribute_names
      self.entity_description.attributesByName.keys
    end

    def cdq(obj = nil)
      if obj
        super(obj)
      else
        @cdq_object ||= super(nil)
      end
    end

    def cdq_initialized?
      !@cdq_object.nil?
    end

  end

  # Register this object for destruction with the current context.  Will not
  # actually be removed until the context is saved.
  #
  def destroy
    managedObjectContext.deleteObject(self)
  end

  def inspect
    description
  end

  # Returns a hash of attributes for the object
  def attributes
    h = {}
    entity.attributesByName.each do |name, desc|
      h[name] = send name
    end
    h
  end

  def log(log_type = nil)
    out = "\nOID: "
    out << oid
    out << "\n"

    atts = entity.attributesByName
    rels = entity.relationshipsByName

    width = (atts.keys.map(&:length) + rels.keys.map(&:length)).max || 0

    atts.each do |name, desc|
      out << "  #{name.ljust(width)} : "
      out << send(name).inspect[0,95 - width]
      out << "\n"
    end

    rels.each do |name, desc|
      rel = CDQRelationshipQuery.new(self, name, nil, context: managedObjectContext)
      if desc.isToMany
        out << "  #{name.ljust(width)} : "
        out << rel.count.to_s
        out << ' (count)'
      else
        out << "  #{name.ljust(width)} : "
        out << (rel.first && rel.first.oid || "nil")
      end
    end
    out << "\n"

    if log_type == :string
      out
    else
      NSLog out
    end
  end

  def ordered_set?(name)
    # isOrdered is returning 0/1 instead of documented BOOL
    ordered = entity.relationshipsByName[name].isOrdered
    return true if ordered == true || ordered == 1
    return false if ordered == false || ordered == 0
  end

  def set_to_extend(name)
    if ordered_set?(name)
      mutableOrderedSetValueForKey(name)
    else
      mutableSetValueForKey(name)
    end
  end

  def oid
    objectID.URIRepresentation.absoluteString.inspect
  end

  protected

  # Called from method that's dynamically added from
  # +[CoreDataManagedObjectBase defineRelationshipMethod:]
  def relationshipByName(name)
    willAccessValueForKey(name)
    set = CDQRelationshipQuery.extend_set(set_to_extend(name), self, name)
    didAccessValueForKey(name)
    set
  end

end
