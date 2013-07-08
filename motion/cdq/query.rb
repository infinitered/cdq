
module CDQ
  class CDQQuery < CDQObject

    EMPTY = Object.new

    attr_reader :predicate, :sort_descriptors

    def initialize(opts = {})
      @predicate = opts[:predicate]
      @limit = opts[:limit]
      @offset = opts[:offset]
      @sort_descriptors = opts[:sort_descriptors] || []
      @saved_key = opts[:saved_key]
    end

    def limit(value = EMPTY)
      if value == EMPTY
        @limit
      else
        new(limit: value)
      end
    end

    def offset(value = EMPTY)
      if value == EMPTY
        @offset
      else
        new(offset: value)
      end
    end

    # Combine this query with others in an intersection ("and") relationship
    def and(query = nil, *args)
      merge_query(query, :and, *args) do |left, right|
        NSCompoundPredicate.andPredicateWithSubpredicates([left, right])
      end
    end
    alias_method :where, :and

    # Combine this query with others in a union ("or") relationship
    def or(query = nil, *args)
      merge_query(query, :or, *args) do |left, right|
        NSCompoundPredicate.orPredicateWithSubpredicates([left, right])
      end
    end

    # Create a new query with the same values as this one, optionally overriding
    # any of them in the options
    def new(opts = {})
      self.class.new(locals.merge(opts))
    end

    def locals
      { sort_descriptors: sort_descriptors,
        predicate: predicate,
        limit: limit,
        offset: offset }
    end

    def sort_by(key, dir = :ascending)
      if dir.to_s[0,4].downcase == 'desc'
        ascending = false
      else 
        ascending = true
      end

      new(sort_descriptors: @sort_descriptors + [NSSortDescriptor.sortDescriptorWithKey(key, ascending: ascending)])
    end

    def fetch_request
      NSFetchRequest.new.tap do |req|
        req.predicate = predicate
        req.fetchLimit = limit if limit
        req.fetchOffset = offset if offset
        req.sortDescriptors = sort_descriptors unless sort_descriptors.empty?
      end
    end

    private

    def merge_query(query, operation, *args, &block)
      key_to_save = nil
      case query
      when Hash
        subquery = query.inject(CDQQuery.new) do |memo, (key, value)|
          memo.and(key).eq(value)
        end
        other_predicate = subquery.predicate
        new_limit = limit
        new_offset = offset
        new_sort_descriptors = sort_descriptors
      when Symbol
        return CDQPartialPredicate.new(query, self, operation)
      when NilClass
        if @saved_key
          return CDQPartialPredicate.new(@saved_key, self, operation)
        else
          raise "Zero-argument 'and' and 'or' can only be used if there is a key in the preceding predicate"
        end
      when CDQQuery
        new_limit = [limit, query.limit].compact.last
        new_offset = [offset, query.offset].compact.last
        new_sort_descriptors = sort_descriptors + query.sort_descriptors
        other_predicate = query.predicate
      when NSPredicate
        other_predicate = query
        new_limit = limit
        new_offset = offset
        new_sort_descriptors = sort_descriptors
        key_to_save = args.first
      when String
        other_predicate = NSPredicate.predicateWithFormat(query, argumentArray: args)
        new_limit = limit
        new_offset = offset
        new_sort_descriptors = sort_descriptors
      end
      if predicate
        new_predicate = block.call(predicate, other_predicate)
      else
        new_predicate = other_predicate
      end
      new(predicate: new_predicate, limit: new_limit, offset: new_offset, sort_descriptors: new_sort_descriptors, saved_key: key_to_save)
    end

  end
end

