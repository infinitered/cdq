
module CDQ

  class CDQModelManager

    attr_writer :current

    def initialize(config = nil)
      @config = config || CDQConfig.default
    end

    def current
      @current ||= load_model
    end

    private

    def load_model
      if @config.model_url.nil?
        raise "No model file.  Cannot create an NSManagedObjectModel without one."
      end
      NSManagedObjectModel.alloc.initWithContentsOfURL(@config.model_url)
    end

  end

end
