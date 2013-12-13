module CDQ


  # = Configure the CDQ Stack
  #
  # This class wraps the YAML configuration file that will allow you to
  # override the names used when setting up the database file and finding the
  # model file.  This file is named <tt>cdq.yml</tt> and must be found at the
  # root of your resources directory.  It supports the following top-level keys:
  #
  #   [name]          The root name for both database and model
  #   [database_name] The root name for the database file (relative to the documents directory)
  #   [model_name]    The root name for the model file (relative to the bundle directory)
  #
  # Using the config file is not necessary.  If you do not include it, the bundle display name
  # will be used.  For most people with a new app, this is what you want to do, especially if
  # you are using ruby-xcdm schemas.  The only case where using the config file is required
  # is when you want to use CDQManagedObject-based models with a custom model or database, because
  # class loading order of operations makes it impossible to configure from within your
  # AppDelegate.
  #
  class CDQConfig

    attr_reader :config_file, :database_name, :model_name, :name

    def initialize(config_file)
      @config_file = config_file
      if config_file && File.file?(config_file)
        h = File.open(config_file) { |f| YAML.load(f.read) }
      else
        h = {}
      end
      @name = h['name'] || NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName")
      @database_name = h['database_name'] || name
      @model_name = h['model_name'] || name
    rescue => e
      puts e.backtrace
      raise
    end

    def database_url
      dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).last
      path = File.join(dir, database_name + '.sqlite')
      NSURL.fileURLWithPath(path)
    end

    def model_url
      NSBundle.mainBundle.URLForResource(model_name, withExtension: "momd");
    end

    def self.default
      @default ||=
        begin
          cf_file = NSBundle.mainBundle.pathForResource("cdq", ofType: "yml");
          new(cf_file)
        end
    end
  end

end


