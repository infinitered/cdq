
module CDQ

  class CDQRelationshipQuery < CDQTargetedQuery

    def initialize(owner, name, set = nil, opts = {})
      @owner = owner
      @relationship_name = name
      @set = set || @owner.send(name)
      relationship = owner.entity.relationshipsByName[name]
      @inverse_rel = relationship.inverseRelationship
      entity_description = relationship.destinationEntity
      target_class = constantize(entity_description.managedObjectClassName)
      super(entity_description, target_class, opts)
      if @inverse_rel.isToMany
        @predicate = self.where(@inverse_rel.name.to_sym).contains(@owner).predicate
      else
        @predicate = self.where(@inverse_rel.name.to_sym => @owner).predicate
      end
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
      if @inverse_rel.isToMany
        obj.send(@inverse_rel.name).addObject(@owner)
      else
        obj.send("#{@inverse_rel.name}=", @owner)
      end
      @set.addObject obj
    end
    alias_method :<<, :add

    def self.extend_set(set, owner, name)
      set.extend SetExt
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

      def array
        self.allObjects
      end

      def first
        array.first
      end

      def respond_to?(method)
        @__query__.respond_to?(method) || super(method)
      end

      def method_missing(method, *args, &block)
        if respond_to?(method)
          @__query__.send(method, *args, &block)
        else
          super
        end
      end

    end

  end

end
