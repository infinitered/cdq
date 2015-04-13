
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
    alias :length :count
    alias :size :count

    def get
      @objects
    end

    def array
      @objects
    end

    def first(n = 1)
      n == 1 ? @objects.first : @objects.first(n)
    end

    def last(n = 1)
      n == 1 ? @objects.last : @objects.last(n)
    end

  end
end

