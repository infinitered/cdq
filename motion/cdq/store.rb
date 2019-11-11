
module CDQ

  class CDQStoreManager

    STORE_DID_INITIALIZE_NOTIFICATION = 'com.infinitered.cdq.store.did_initialize'

    attr_writer :current

    def initialize(opts = {})
      @config = opts[:config] || CDQConfig.default
      @model_manager = opts[:model_manager]
    end

    def new(opts = {})
      @config = opts[:config] || CDQConfig.default
      @model_manager = opts[:model_manager] || CDQ.cdq.models
    end

    def current
      @current ||= create_store
    end

    def reset!
      path = @config.database_url.absoluteString
      NSFileManager.defaultManager.removeItemAtURL(@config.database_url, error: nil)
      NSFileManager.defaultManager.removeItemAtURL(NSURL.URLWithString("#{path}-shm"), error: nil)
      NSFileManager.defaultManager.removeItemAtURL(NSURL.URLWithString("#{path}-wal"), error: nil)
    end

    def invalid?
      !@current && @model_manager.invalid?
    end

    private

    def create_store
      if invalid?
        raise "No model found.  Can't create a persistent store coordinator without it."
      else
        create_local_store
      end
    end

    def create_local_store
      coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model_manager.current)
      error = Pointer.new(:object)
      options = { NSMigratePersistentStoresAutomaticallyOption => true,
                  NSInferMappingModelAutomaticallyOption => true }
      url = @config.database_url
      mkdir_p File.dirname(url.path)
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
      Dispatch::Queue.main.after(0) {
        # This block is executed in a next run loop.
        # So the managed object context has a store coordinator in this point.
        NSNotificationCenter.defaultCenter.postNotificationName(STORE_DID_INITIALIZE_NOTIFICATION, object:coordinator)
      }
      coordinator
    end

    def mkdir_p dir
      error = Pointer.new(:object)
      m = NSFileManager.defaultManager
      r = m.createDirectoryAtPath dir, withIntermediateDirectories:true, attributes:nil, error:error
      unless r
        NSLog "#{error[0].localizedDescription}"
        raise error[0].localizedDescription
      end
    end

  end

end
