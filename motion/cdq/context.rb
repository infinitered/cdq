module CDQ

  class CDQContextManager

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
    def push(context, &block)
      @has_been_set_up = true
      if block_given?
        save_stack do
          push_to_stack(context)
          block.call
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
        end
      else
        pop_from_stack
      end
    end

    # The current context at the top of the stack.
    #
    def current
      if stack.empty? && !@has_been_set_up
        new(NSMainQueueConcurrencyType)
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
    def new(concurrency_type, &block)
      @has_been_set_up = true
      
      context = NSManagedObjectContext.alloc.initWithConcurrencyType(concurrency_type)
      if current
        context.parentContext = current
      else
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
      end
      push(context, &block)
    end

    # Save all contexts in the stack, starting with the current and working down.
    #
    def save(options = {})
      set_timestamps
      always_wait = options[:always_wait]
      stack.reverse.each do |context|
        if always_wait || context.concurrencyType == NSMainQueueConcurrencyType
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
      eos = current.insertedObjects.allObjects + current.updatedObjects.allObjects
      eos.each do |e|
        e.created_at ||= now if e.respond_to? :created_at=
        e.updated_at = now if e.respond_to? :updated_at=
      end
    end

  end

end
