
module CDQ

  class CDQObject

    include CDQ

    def contexts
      @@context_manager ||= CDQContextManager.new(store: stores.current)
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
      if opts[:context]
        contexts.push(opts[:context])
        return true
      elsif opts[:store]
        stores.current = opts[:store]
      elsif opts[:model]
        models.current = opts[:model]
      end
      contexts.new(NSMainQueueConcurrencyType)
      true
    end

    def save(*args)
      contexts.save(*args)
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

