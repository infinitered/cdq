
module CDQ

  class CDQModelManager

    attr_writer :current

    def initialize(opts = {})
      @config = opts[:config] || CDQConfig.default
    end

    def current
      @current ||= load_model
    end

    def invalid?
      !@current && @config.model_url.nil?
    end

    private

    def load_model
      if invalid?
        raise "No model file.  Cannot create an NSManagedObjectModel without one."
      else
        NSManagedObjectModel.alloc.initWithContentsOfURL(@config.model_url)
      end
    end

  end

end
