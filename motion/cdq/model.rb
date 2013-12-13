
module CDQ

  class CDQModelManager

    def initialize(opts = {})
      @config = opts[:config] || CDQConfig.default
      @current = load_model
    end

    def current
      @current
    end

    private

    def load_model
      NSManagedObjectModel.alloc.initWithContentsOfURL(@config.model_url)
    end

  end

end
