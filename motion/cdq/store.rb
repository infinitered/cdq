
module CDQ

  class CDQStoreManager

    def initialize(opts = {})
      @name = opts[:name] || NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName")
      @database_path = database_path(@name)
      @model = opts[:model]
      @store_coordinator = create_store
    end

    def current
      @store_coordinator
    end

    def reset!
      NSFileManager.defaultManager.removeItemAtPath(@database_path, error: nil)
    end

    private

    def database_path(name)
      dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).last
      path = File.join(dir, name + '.sqlite')
    end

    def create_store
      coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model)
      error = Pointer.new(:object)
      options = { NSMigratePersistentStoresAutomaticallyOption => true,
                  NSInferMappingModelAutomaticallyOption => true }
      url = NSURL.fileURLWithPath(@database_path)
      store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                     configuration:nil,
                                                     URL:url,
                                                     options:options,
                                                     error:error)
      if store.nil?
        error[0].userInfo['metadata'] && error[0].userInfo['metadata'].each do |key, value|
          puts "#{key}: #{value}"
        end
        raise error[0].userInfo['reason']
      end
      coordinator
    end
  end

end
