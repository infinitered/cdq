
module CDQ
  class CDQObjectProxy < CDQObject

    def initialize(object)
      @object = object
    end

    def get
      @object
    end

    def method_missing(*args)
      if @object.entity.relationshipsByName[args.first]
        CDQRelationshipQuery.new(@object, args.first)
      elsif @object.respond_to?(args.first)
        @object.send(*args)
      end
    end

    def ==(other)
      super(other) || @object == other
    end

  end
end

