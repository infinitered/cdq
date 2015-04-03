
module CDQ

  class CDQRelationshipQuery < CDQTargetedQuery

    def initialize(owner, name, set = nil, opts = {})
      @owner = owner ? WeakRef.new(owner) : nil
      @relationship_name = name
      @set = set ? WeakRef.new(set) : nil
      relationship = owner.entity.relationshipsByName[name]
      if relationship.isToMany
        if @owner.ordered_set?(name)
          @set ||= @owner.mutableOrderedSetValueForKey(name)
        else
          @set ||= @owner.mutableSetValueForKey(name)
        end
      end
      @inverse_rel = relationship.inverseRelationship
      entity_description = relationship.destinationEntity
      target_class = constantize(entity_description.managedObjectClassName)
      super(entity_description, target_class, opts)
      if @inverse_rel.isToMany
        @predicate = self.where(@inverse_rel.name.to_sym).contains(owner).predicate
      else
        @predicate = self.where(@inverse_rel.name.to_sym => @owner).predicate
      end
    end
    
    def dealloc
      super
    end

    # Creates a new managed object within the target relationship
    #
    def new(opts = {})
      super(opts).tap do |obj|
        add(obj)
      end
    end

    # Add an existing object to the relationship
    #
    def add(obj)
      @set.addObject obj
    end
    alias_method :<<, :add

    # Remove objects from the relationship
    #
    def remove(obj)
      @set.removeObject obj
    end

    def self.extend_set(set, owner, name)
      set.extend SetExt
      set.extend Enumerable
      set.__query__ = self.new(owner, name, set)
      set
    end

    # A Core Data relationship set is extended with this module to provide
    # scoping by forwarding messages to a CDQRelationshipQuery instance knows
    # how to create further queries based on the underlying relationship.
    module SetExt
      attr_accessor :__query__

      def set
        self
      end

      # This works in a special way.  If we're extending a regular NSSet, it will
      # create a new method that calls allObjects.  If we're extending a NSOrderedSet,
      # the override will not work, and we get the array method already defined on
      # NSOrderedSet, which is actually exactly what we want.
      def array
        self.allObjects
      end

      def first
        array.first
      end

      # duplicating a lot of common methods because it's way faster than using method_missing
      #
      def each(*args, &block)
        array.each(*args, &block)
      end

      def add(obj)
        @__query__.add(obj)
      end
      alias_method :<<, :add

      def create(opts = {})
        @__query__.create(opts)
      end

      def new(opts = {})
        @__query__.new(opts)
      end

      def remove(opts = {})
        @__query__.remove(opts)
      end

      def where(*args)
        @__query__.where(*args)
      end

      def sort_by(*args)
        @__query__.sort_by(*args)
      end

      def limit(*args)
        @__query__.limit(*args)
      end

      def offset(*args)
        @__query__.offset(*args)
      end

      def respond_to?(method)
        super(method) || @__query__.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        if @__query__.respond_to?(method)
          @__query__.send(method, *args, &block)
        else
          super
        end
      end

    end

  end

end
