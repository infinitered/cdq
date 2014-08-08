
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
      @icloud = opts[:icloud] || opts[:iCloud] || @config.icloud
      @icloud_container = @config.icloud_container
    end

    def current
      @current ||= create_store
    end

    def reset!
      NSFileManager.defaultManager.removeItemAtURL(@config.database_url, error: nil)
    end

    def invalid?
      !@current && @model_manager.invalid?
    end

    private

    def create_store
      if invalid?
        raise "No model found.  Can't create a persistent store coordinator without it."
      else
        if @icloud
          create_icloud_store
        else
          create_local_store
        end
      end
    end

    def create_icloud_store
      coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model_manager.current)

      Dispatch::Queue.concurrent.async {
        # get icloud first container
        url = @config.database_url
        icloud_url = NSFileManager.defaultManager.URLForUbiquityContainerIdentifier(@icloud_container)
        if icloud_url
          error = Pointer.new(:object)
          icloud_url = icloud_url.URLByAppendingPathComponent("data")
          error = Pointer.new(:object)
          options = { NSMigratePersistentStoresAutomaticallyOption => true,
                      NSInferMappingModelAutomaticallyOption => true,
                      NSPersistentStoreUbiquitousContentNameKey => url.path.lastPathComponent.gsub(".", "_"),
                      NSPersistentStoreUbiquitousContentURLKey => icloud_url,
                    }
          coordinator.lock
          store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                     configuration:nil,
                                                     URL:url,
                                                     options:options,
                                                     error:error)
          coordinator.unlock

          if store.nil?
            error[0].userInfo['metadata'] && error[0].userInfo['metadata'].each do |key, value|
              NSLog "#{key}: #{value}"
            end
            raise error[0].userInfo['reason']
          end

        else
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
        end
        Dispatch::Queue.main.after(0) {
          # This block is executed in a next run loop.
          # So the managed object context has a store coordinator in this point.
          NSNotificationCenter.defaultCenter.postNotificationName(STORE_DID_INITIALIZE_NOTIFICATION, object:coordinator)
        }
      }
      coordinator
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
