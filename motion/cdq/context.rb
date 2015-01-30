module CDQ

  class CDQContextManager

    include Deprecation

    BACKGROUND_SAVE_NOTIFICATION = 'com.infinitered.cdq.context.background_save_completed'
    DID_FINISH_IMPORT_NOTIFICATION = 'com.infinitered.cdq.context.did_finish_import'

    def initialize(opts = {})
      @store_manager = opts[:store_manager]
    end

    def dealloc
      NSNotificationCenter.defaultCenter.removeObserver(self) if @observed_context
      super
    end

    # Push a new context onto the stack for the current thread, making that context the
    # default. If a block is supplied, push for the duration of the block and then
    # return to the previous state.
    #
    def push(context, options = {}, &block)
      @has_been_set_up = true

      unless context.is_a? NSManagedObjectContext
        context = create(context, options)
      end

      if block_given?
        save_stack do
          context = push_to_stack(context)
          block.call
          context
        end
      else
        push_to_stack(context)
      end
    end

    # Pop the top context off the stack.  If a block is supplied, pop for the
    # duration of the block and then return to the previous state.
    #
    def pop(&block)
      if block_given?
        save_stack do
          rval = pop_from_stack
          block.call
          rval
        end
      else
        pop_from_stack
      end
    end

    # The current context at the top of the stack.
    #
    def current
      if stack.empty? && !@has_been_set_up
        push(NSMainQueueConcurrencyType)
      end
      stack.last
    end

    # An array of all contexts, from bottom to top of the stack.
    #
    def all
      stack.dup
    end

    # Remove all contexts.
    #
    def reset!
      self.stack = []
    end

    # Create and push a new context with the specified concurrency type.  Its parent
    # will be set to the previous head context.  If a block is supplied, the new context
    # will exist for the duration of the block and then the previous state will be restore_managerd.
    #
    # REMOVE1.1
    #
    def new(concurrency_type, &block)
      deprecate "cdq.contexts.new() is deprecated.  Use push() or create()"
      context = create(concurrency_type)
      push(context, {}, &block)
    end

    # Create a new context by type, setting upstream to the topmost context if available,
    # or to the persistent store coordinator if not.  Return the context but do NOT push it
    # onto the stack.
    #
    def create(concurrency_type, options = {}, &block)
      @has_been_set_up = true

      case concurrency_type
      when :main
        context = NSManagedObjectContext.alloc.initWithConcurrencyType(NSMainQueueConcurrencyType)
      when :private_queue, :private
        context = NSManagedObjectContext.alloc.initWithConcurrencyType(NSPrivateQueueConcurrencyType)
      else
        context = NSManagedObjectContext.alloc.initWithConcurrencyType(concurrency_type)
      end

      if stack.empty?
        if @store_manager.invalid?
          raise "store coordinator not found. Cannot create the first context without one."
        else
          context.mergePolicy = NSMergePolicy.alloc.initWithMergeType(NSMergeByPropertyObjectTrumpMergePolicyType)
          context.performBlockAndWait ->{
            coordinator = @store_manager.current
            context.persistentStoreCoordinator = coordinator
            #Dispatch::Queue.main.async {
            NSNotificationCenter.defaultCenter.addObserver(self, selector:"did_finish_import:", name:NSPersistentStoreDidImportUbiquitousContentChangesNotification, object:nil)
            @observed_context = context
            #}
          }
        end
      else
        context.parentContext = stack.last
      end

      if options[:named]
        if respond_to?(options[:named])
          raise "Cannot name a context '#{options[:named]}': conflicts with existing method"
        end
        self.class.send(:define_method, options[:named]) do
          context
        end
      end
      context
    end

    # Save all passed contexts in order.  If none are supplied, save all
    # contexts in the stack, starting with the current and working down.  If
    # you pass a symbol instead of a context, it will look up context with
    # that name.
    #
    # Options:
    #
    #   always_wait: If true, force use of performBlockAndWait for synchronous
    #     saves.  By default, private queue saves are performed asynchronously.
    #     Main queue saves are always synchronous if performed from the main
    #     queue.
    #
    def save(*contexts_and_options)

      if contexts_and_options.last.is_a? Hash
        options = contexts_and_options.pop
      else
        options = {}
      end

      if contexts_and_options.empty?
        contexts = stack.reverse
      else
        # resolve named contexts
        contexts = contexts_and_options.map do |c|
          if c.is_a? Symbol
            send(c)
          else
            c
          end
        end
      end

      set_timestamps
      always_wait = options[:always_wait]
      contexts.each do |context|
        if context.concurrencyType == NSMainQueueConcurrencyType && NSThread.isMainThread
          with_error_object do |error|
            context.save(error)
          end
        elsif always_wait
          context.performBlockAndWait( -> {

            with_error_object do |error|
              context.save(error)
            end

          } )
        elsif context.concurrencyType == NSPrivateQueueConcurrencyType
          task_id = UIApplication.sharedApplication.beginBackgroundTaskWithExpirationHandler( -> { NSLog "CDQ Save Timed Out" } )

          if task_id == UIBackgroundTaskInvalid
            context.performBlockAndWait( -> {

              with_error_object do |error|
                context.save(error)
              end

            } )
          else
            context.performBlock( -> {

              # Let the application know we're doing something important
              with_error_object do |error|
                context.save(error)
              end

              UIApplication.sharedApplication.endBackgroundTask(task_id)

              NSNotificationCenter.defaultCenter.postNotificationName(BACKGROUND_SAVE_NOTIFICATION, object: context)

            } )
          end
        else
          with_error_object do |error|
            context.save(error)
          end
        end
      end
      true
    end

    # Run the supplied block in a new context with a private queue.  Once the
    # block exits, the context will be forgotten, so any changes made must be
    # saved within the block.
    #
    # Note that the CDQ context stack, which is used when deciding what to save
    # with `cdq.save` is stored per-thread, so the stack inside the block is
    # different from the stack outside the block. If you push any more contexts
    # inside, they will also disappear when the thread terminates.
    #
    # The thread is also unique.  If you call `background` multiple times, it will
    # be a different thread each time with no persisted state.
    #
    # Options:
    #   wait: If true, run the block synchronously
    #
    def background(options = {}, &block)
      # Create a new private queue context with the main context as its parent
      context = create(NSPrivateQueueConcurrencyType)

      on(context, options) do
        push(context, {}, &block)
      end

    end

    # Run a block on the supplied context using performBlock.  If context is a
    # symbol, it will look up the corresponding named context and use that
    # instead.
    #
    # Options:
    #   wait: If true, run the block synchronously
    #
    def on(context, options = {}, &block)

      if context.is_a? Symbol
        context = send(context)
      end

      if options[:wait]
        context.performBlockAndWait(block)
      else
        context.performBlock(block)
      end
    end

    def did_finish_import(notification)
      @observed_context.performBlockAndWait ->{
        @observed_context.mergeChangesFromContextDidSaveNotification(notification)
        NSNotificationCenter.defaultCenter.postNotificationName(DID_FINISH_IMPORT_NOTIFICATION, object:self, userInfo:{context: @observed_context})
      }
    end


    private

    def push_to_stack(value)
      lstack = stack
      lstack << value
      self.stack = lstack
      value
    end

    def pop_from_stack
      lstack = stack
      value = lstack.pop
      self.stack = lstack
      value
    end

    def save_stack(&block)
      begin
        saved_stack = all
        block.call
      ensure
        self.stack = saved_stack
      end
    end

    def stack
      Thread.current[:"cdq.context.stack.#{object_id}"] || []
    end

    def stack=(value)
      Thread.current[:"cdq.context.stack.#{object_id}"] = value
    end

    def with_error_object(default = nil, &block)
      error = Pointer.new(:object)
      result = block.call(error)
      if error[0]
        print_error("Error while fetching", error[0])
        raise "Error while fetching: #{error[0].debugDescription}"
      end
      result || default
    end

    def print_error(message, error, indent = "")
      puts indent + message + error.localizedDescription
      if error.userInfo['reason']
        puts indent + error.userInfo['reason']
      end
      if error.userInfo['metadata']
        error.userInfo['metadata'].each do |key, value|
          puts indent + "#{key}: #{value}"
        end
      end
      if !error.userInfo[NSDetailedErrorsKey].nil?
        error.userInfo[NSDetailedErrorsKey].each do |key, value|
          if key.instance_of? NSError
            print_error("Sub-Error: ", key, indent + "   ")
          else
            puts indent + "#{key}: #{value}"
          end
        end
      end
    end

    def set_timestamps
      now = Time.now

      current.insertedObjects.allObjects.each do |e|
        e.created_at = now if e.respond_to? :created_at=
        e.updated_at = now if e.respond_to? :updated_at=
      end

      current.updatedObjects.allObjects.each do |e|
        e.updated_at = now if e.respond_to? :updated_at=
      end

    end

  end

end
