
module CDQ

  #
  # CDQ Queries are the primary way of describing a set of objects.
  #
  class CDQQuery < CDQObject

    # @private
    #
    # This is a singleton object needed to represent "empty" in limit and
    # offset, because they need to be able to accept nil as a real value.
    #
    EMPTY = Object.new

    attr_reader :predicate, :sort_descriptors

    def initialize(opts = {})
      @predicate = opts[:predicate]
      @limit = opts[:limit]
      @offset = opts[:offset]
      @sort_descriptors = opts[:sort_descriptors] || []
      @saved_key = opts[:saved_key]
    end

    # Return or set the fetch limit.  If passed an argument, return a new
    # query with the specified limit value.  Otherwise, return the current
    # value.
    #
    def limit(value = EMPTY)
      if value == EMPTY
        @limit
      else
        clone(limit: value)
      end
    end

    # Return or set the fetch offset.  If passed an argument, return a new
    # query with the specified offset value.  Otherwise, return the current
    # value.
    #
    def offset(value = EMPTY)
      if value == EMPTY
        @offset
      else
        clone(offset: value)
      end
    end

    # Combine this query with others in an intersection ("and") relationship. Can be
    # used to begin a new query as well, especially when called in its <tt>where</tt>
    # variant.
    #
    # The query passed in can be a wide variety of types:
    #
    # Symbol: This is by far the most common, and it is also a special
    # case -- the return value when passing a symbol is a CDQPartialPredicate,
    # rather than CDQQuery. Methods on CDQPartialPredicate are then comparison
    # operators against the attribute indicated by the symbol itself, which take
    # a value operand.  For example:
    #
    #   query.where(:name).equal("Chuck").and(:title).not_equal("Manager")
    #
    # @see CDQPartialPredicate
    #
    # String: Interpreted as an NSPredicate format string.  Additional arguments are
    # the positional parameters.
    #
    # NilClass: If the argument is nil (most likely because it was omitted), and there
    # was a previous use of a symbol, then reuse that last symbol. For example:
    #
    #   query.where(:name).contains("Chuck").and.contains("Norris")
    #
    # CDQQuery: If you have another CDQQuery from somewhere else, you can pass it in directly.
    #
    # NSPredicate: You can pass in a raw NSPredicate and it will work as you'd expect.
    #
    # Hash: Each key/value pair is treated as equality and anded together.
    #
    def and(query = nil, *args)
      merge_query(query, :and, *args) do |left, right|
        NSCompoundPredicate.andPredicateWithSubpredicates([left, right])
      end
    end
    alias_method :where, :and

    # Combine this query with others in a union ("or") relationship.  Accepts
    # all the same argument types as <tt>and</tt>.
    def or(query = nil, *args)
      merge_query(query, :or, *args) do |left, right|
        NSCompoundPredicate.orPredicateWithSubpredicates([left, right])
      end
    end

    # Add a new sort key.  Multiple invocations add additional sort keys rather than replacing
    # old ones.
    #
    #   @param key The attribute to sort on
    #   @param options Optional options.
    #
    # Options include:
    #   order:  If :descending or (or :desc), order is descrnding.  Otherwise,
    #           it is ascending.
    #   case_insensitive:  True or false.  If true, the sort descriptor is
    #           built using <tt>localizedCaseInsensitiveCompare</tt>
    #
    def sort_by(key, options = {})
      # backwards compat:  if options is not a hash, it is a sort ordering.
      unless options.is_a?Hash
        sort_order = options
        options = {
          order: sort_order,
          case_insensitive: false,
        }
      end

      options = {
        order: :ascending,
      }.merge(options)

      order = options[:order].to_s

      if order[0,4].downcase == 'desc'
        ascending = false
      else
        ascending = true
      end

      if options[:case_insensitive]
        descriptor = NSSortDescriptor.sortDescriptorWithKey(key, ascending: ascending, selector: "localizedCaseInsensitiveCompare:")
      else
        descriptor = NSSortDescriptor.sortDescriptorWithKey(key, ascending: ascending)
      end

      clone(sort_descriptors: @sort_descriptors + [descriptor])
    end

    # Return an NSFetchRequest that will implement this query
    def fetch_request
      NSFetchRequest.new.tap do |req|
        req.predicate = predicate
        req.fetchLimit = limit if limit
        req.fetchOffset = offset if offset
        req.sortDescriptors = sort_descriptors unless sort_descriptors.empty?
      end
    end

    private

    # Create a new query with the same values as this one, optionally overriding
    # any of them in the options
    def clone(opts = {})
      self.class.new(locals.merge(opts))
    end

    def locals
      { sort_descriptors: sort_descriptors,
        predicate: predicate,
        limit: limit,
        offset: offset }
    end

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
      clone(predicate: new_predicate, limit: new_limit, offset: new_offset, sort_descriptors: new_sort_descriptors, saved_key: key_to_save)
    end

  end
end

