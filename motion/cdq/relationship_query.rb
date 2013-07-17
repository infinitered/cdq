
module CDQ

  class CDQRelationshipQuery < CDQTargetedQuery

    def initialize(owner, name, opts = {})
      relationship = owner.entity.relationshipsByName[name]
      entity_description = relationship.destinationEntity
      target_class = constantize(entity_description.managedObjectClassName)
      super(entity_description, target_class, opts)
      @predicate = self.where(relationship.inverseRelationship.name.to_sym => owner).predicate
    end

  end

end
