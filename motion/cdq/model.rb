
module CDQ

  class CDQModelManager

    def initialize(opts = {})
      @name = opts[:name] || NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName")
      @managed_object_model = load_model
    end

    def current
      @managed_object_model
    end

    private

    def load_model
      modelURL = NSBundle.mainBundle.URLForResource(@name, withExtension: "momd");
      NSManagedObjectModel.alloc.initWithContentsOfURL(modelURL)
    end

  end

end
