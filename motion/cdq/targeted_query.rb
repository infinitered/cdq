
module CDQ #:nodoc:

  class CDQTargetedQuery < CDQQuery

    include Enumerable

    attr_reader :entity_description

    # Create a new CDQTargetedContext.  Takes an entity description, an optional
    # implementation class, and a hash of options that will be passed to the CDQQuery
    # constructor.
    #
    def initialize(entity_description, target_class = nil, opts = {})
      @entity_description = entity_description
      @target_class = target_class ||
        NSClassFromString(entity_description.managedObjectClassName) ||
        CDQManagedObject
      @context = opts.delete(:context)
      super(opts)
    end

    # The current context, taken from the environment or overriden by <tt>in_context</tt>
    #
    def context
      @context || contexts.current
    end

    # Return the number of matching entities.
    #
    # Causes execution.
    #
    def count
      raise("No context has been set.  Probably need to run cdq.setup") unless context
      with_error_object(0) do |error|
        context.countForFetchRequest(fetch_request, error:error)
      end
    end
    alias :length :count
    alias :size :count

    # Return all matching entities.
    #
    # Causes execution.
    #
    def array
      raise("No context has been set.  Probably need to run cdq.setup") unless context
      with_error_object([]) do |error|
        context.executeFetchRequest(fetch_request, error:error)
      end
    end
    alias_method :to_a, :array

    # Convenience method for referring to all matching entities.  No-op.  You must
    # still call <tt>array</tt> or another executing method
    #
    def all
      self
    end

    # Return the first entity matching the query.
    #
    # Causes execution.
    #
    def first
      limit(1).array.first
    end

    # Fetch a single entity from the query by index.  If the optional
    # <tt>length</tt> parameter is supplied, fetch a range of length <tt>length</tt>
    # starting at <tt>index</tt>
    #
    # Causes execution.
    #
    def [](index, length = nil)
      if length
        offset(index).limit(length).array
      else
        offset(index).first
      end
    end

    # Iterate over each entity matched by the query.  You can also use any method from the
    # Enumerable module in the standard library that does not depend on ordering.
    #
    # Causes execution.
    #
    def each(*args, &block)
      array.each(*args, &block)
    end

    # Returns the fully-contstructed fetch request, which can be executed outside of CDQ.
    #
    def fetch_request
      super.tap do |req|
        req.entity = @entity_description
        req.predicate ||= NSPredicate.predicateWithValue(true)
      end
    end

    # Create a new entity in the current context.  Accepts a hash of attributes that will be assigned to
    # the newly-created entity.  Does not save the context.
    #
    def new(opts = {})
      @target_class.alloc.initWithEntity(@entity_description, insertIntoManagedObjectContext: context).tap do |entity|
        opts.each { |k, v| entity.send("#{k}=", v) }
      end
    end

    # Create a new entity in the current context.  Accepts a hash of attributes that will be assigned to
    # the newly-created entity.  Does not save the context.
    #
    def create(*args)
      new(*args)
    end

    # Create a named scope.  The query is any valid CDQ query.
    #
    # Example:
    #
    # cdq('Author').scope(:first_published, cdq(:published).eq(true).sort_by(:published_at).limit(1))
    #
    # cdq('Author').first_published.first => #<Author>
    #
    def scope(name, query = nil, &block)
      if query.nil? && block_given?
        named_scopes[name] = block
      elsif query
        named_scopes[name] = query
      else
        raise ArgumentError.new("You must supply a query OR a block that returns a query to scope")
      end
    end

    # Override the context in which to perform this query.  This forever forces the
    # specified context for this particular query, so if you save the it for later
    # use (such as defining a scope) bear in mind that changes in the default context
    # will have no effect when running this.
    #
    def in_context(context)
      clone(context: context)
    end

    # Any unknown method will be checked against the list of named scopes.
    #
    def method_missing(name, *args)
      scope = named_scopes[name]
      case scope
      when CDQQuery
        where(scope)
      when Proc
        where(scope.call(*args))
      else
        super(name, *args)
      end
    end

    def log(log_type = nil)
      out = "\n\n                              ATTRIBUTES"
      out <<   " \n Name                 | type                | default                       |"
      line =   " \n- - - - - - - - - - - | - - - - - - - - - - | - - - - - - - - - - - - - - - |"
      out << line

      entity_description.attributesByName.each do |name, desc|
        out << " \n #{name.ljust(21)}|"
        out << " #{desc.attributeValueClassName.ljust(20)}|"
        out << " #{desc.defaultValue.to_s.ljust(30)}|"
      end

      out << line
      out << "\n\n"

      self.each do |o|
        out << o.log(:string)
      end

      if log_type == :string
        out
      else
        NSLog out
      end
    end

    private

    def oid(obj)
      obj ? obj.oid : "nil"
    end

    def named_scopes
      @@named_scopes ||= {}
      @@named_scopes[@entity_description] ||= {}
    end

    def clone(opts = {})
      CDQTargetedQuery.new(@entity_description, @target_class, locals.merge(opts))
    end

  end
end
