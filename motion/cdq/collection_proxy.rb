
module CDQ
  class CDQCollectionProxy < CDQTargetedQuery

    def initialize(objects, entity_description)
      @objects = objects
      super(entity_description, constantize(entity_description.managedObjectClassName))
      @predicate = self.where("%@ CONTAINS SELF", @objects).predicate
    end

    def count
      @objects.size
    end

    def get
      @objects
    end

    def array
      @objects
    end
    
    def first
      @objects.first
    end

  end
end

