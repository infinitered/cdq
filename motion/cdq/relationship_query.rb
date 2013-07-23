
module CDQ

  class CDQRelationshipQuery < CDQTargetedQuery

    def initialize(owner, name, set = nil, opts = {})
      @owner = owner
      @relationship_name = name
      @set = set || @owner.send(name)
      relationship = owner.entity.relationshipsByName[name]
      @inverse_rel_name = relationship.inverseRelationship.name.to_sym 
      entity_description = relationship.destinationEntity
      target_class = constantize(entity_description.managedObjectClassName)
      super(entity_description, target_class, opts)
      @predicate = self.where(@inverse_rel_name => @owner).predicate
    end

    # Creates a new managed object within the target relationship
    # 
    def new(opts = {})
      super(opts.merge(@inverse_rel_name => @owner)) do |obj|
        @set.addObject obj
      end
    end

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
