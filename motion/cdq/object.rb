
module CDQ

  class CDQObject

    def contexts
      @@context_manager ||= CDQContextManager.new(store_coordinator: stores.current)
    end

    def stores
      @@store_manager ||= CDQStoreManager.new(model: models.current)
    end

    def models
      @@model_manager ||= CDQModelManager.new
    end

    def reset!(opts = {})
      @@context_manager.reset!
      @@context_manager = nil
      @@store_manager.reset!
      @@store_manager = nil
    end

    def setup(opts = {})
      contexts.new(NSPrivateQueueConcurrencyType)
      contexts.new(NSMainQueueConcurrencyType)
    end

    def save
      contexts.save
    end

    protected

    def with_error_object(default, &block)
      error = Pointer.new(:object)
      result = block.call(error)
      if error[0]
        raise "Error while fetching: #{error[0].debugDescription}"
      end
      result || default
    end

  end

end

