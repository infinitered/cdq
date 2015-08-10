
module CDQ

  class CDQObject

    include CDQ

    def contexts
      @@context_manager ||= CDQContextManager.new(store_manager: stores)
    end

    def stores
      @@store_manager ||= CDQStoreManager.new(model_manager: models)
    end

    def models
      @@model_manager ||= CDQModelManager.new
    end

    def reset!(opts = {})
      @@context_manager.reset! if @@context_manager
      @@context_manager = nil
      @@store_manager.reset! if @@store_manager
      @@store_manager = nil
    end

    # Save any data and close down the contexts and store manager.
    # You should be able create a new CDQConfig object and run setup 
    # again to attach to a different database.  However, you need to be sure
    # that all activity is finished, and that any exisitng model instances
    # have been deallocated.
    #------------------------------------------------------------------------------
    def close
      save
      @@context_manager.reset! if @@context_manager
      @@context_manager        = nil
      @@store_manager          = nil
      CDQConfig.default_config = nil
    end

    # You can now pass in a CDQConfig object, which will be used instead of the
    # one loaded from the cdq.yml file.  However, the model file is loaded during
    # the loading of the code - so it can only be overridden using the cdq.yml.
    #------------------------------------------------------------------------------
    def setup(opts = {})
      CDQConfig.default_config = opts[:config] || nil
      if opts[:context]
        contexts.push(opts[:context])
        return true
      elsif opts[:store]
        stores.current = opts[:store]
      elsif opts[:model]
        models.current = opts[:model]
      end
      contexts.push(NSMainQueueConcurrencyType)
      true
    end

    def save(*args)
      contexts.save(*args)
    end

    def background(*args, &block)
      contexts.background(*args, &block)
    end

    def find(oid)
      url = NSURL.URLWithString(oid)
      object_id = stores.current.managedObjectIDForURIRepresentation(url)
      object_id ? contexts.current.existingObjectWithID(object_id, error: nil) : nil
    end

    protected

    def with_error_object(default, &block)
      error = Pointer.new(:object)
      result = block.call(error)
      if error[0]
        p error[0].debugDescription
        raise "Error while fetching: #{error[0].debugDescription}"
      end
      result || default
    end

    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if constant.const_defined?(name, false)
          next candidate unless Object.const_defined?(name)

          # Go down the ancestors to check it it's owned
          # directly before we reach Object or the end of ancestors.
          constant = constant.ancestors.inject do |const, ancestor|
            break const    if ancestor == Object
            break ancestor if ancestor.const_defined?(name, false)
            const
          end

          # owner is in Object, so raise
          constant.const_get(name, false)
        end
      end
    end
  end

end

