
module CDQ
  class CDQObjectProxy < CDQObject

    def initialize(object)
      @object = object
    end

    def get
      @object
    end

    def respond_to?(method)
      super(method) || @object.entity.relationshipsByName[method]
    end

    def method_missing(*args)
      if @object.entity.relationshipsByName[args.first]
        CDQRelationshipQuery.new(@object, args.first)
      else
        super(*args)
      end
    end

    def destroy
      @object.managedObjectContext.deleteObject(@object)
    end
  end
end

