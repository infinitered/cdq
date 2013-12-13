
module CDQ

  class CDQModelManager

    attr_accessor :current

    def initialize(config = nil)
      @config = config || CDQConfig.default
      @current = load_model
    end

    private

    def load_model
      if @config.model_url
        NSManagedObjectModel.alloc.initWithContentsOfURL(@config.model_url)
      end
    end

  end

end
