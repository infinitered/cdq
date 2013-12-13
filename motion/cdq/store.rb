
module CDQ

  class CDQStoreManager

    def initialize(opts = {})
      @config = opts[:config] || CDQConfig.default
      @model = opts[:model]
      @current = create_store
    end

    def current
      @current
    end

    def reset!
      NSFileManager.defaultManager.removeItemAtURL(@config.database_url, error: nil)
    end

    private

    def create_store
      coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model)
      error = Pointer.new(:object)
      options = { NSMigratePersistentStoresAutomaticallyOption => true,
                  NSInferMappingModelAutomaticallyOption => true }
      url = @config.database_url
      store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                     configuration:nil,
                                                     URL:url,
                                                     options:options,
                                                     error:error)
      if store.nil?
        error[0].userInfo['metadata'] && error[0].userInfo['metadata'].each do |key, value|
          NSLog "#{key}: #{value}"
        end
        raise error[0].userInfo['reason']
      end
      coordinator
    end
  end

end
