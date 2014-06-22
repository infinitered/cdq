module CDQ


  # = Configure the CDQ Stack
  #
  # This class wraps the YAML configuration file that will allow you to
  # override the names used when setting up the database file and finding the
  # model file.  This file is named <tt>cdq.yml</tt> and must be found at the
  # root of your resources directory.  It supports the following top-level keys:
  #
  #   [name]              The root name for both database and model
  #   [database_dir]      The root name for the database directory (NSDocumentDirectory or NSApplicationSupportDirectory)
  #   [database_name]     The root name for the database file (relative to the database_dir)
  #   [model_name]        The root name for the model file (relative to the bundle directory)
  #   [icloud]            If it's true, CDQ works with iCloud.
  #   [icloud_container]  Set id of iCloud container if you use iCloud. If it's nil, use first container listed in the com.apple.developer.ubiquity-container-identifiers entitlement array.
  #
  # Using the config file is not necessary.  If you do not include it, the bundle display name
  # will be used.  For most people with a new app, this is what you want to do, especially if
  # you are using ruby-xcdm schemas.  The only case where using the config file is required
  # is when you want to use CDQManagedObject-based models with a custom model or database, because
  # class loading order of operations makes it impossible to configure from within your
  # AppDelegate.
  #
  class CDQConfig

    attr_reader :config_file, :database_name, :database_dir, :model_name, :name, :icloud, :icloud_container

    def initialize(config_file)
      h = nil
      case config_file
      when String
        @config_file = config_file
        h = nil
        if File.file?(config_file)
          h = File.open(config_file) { |f| YAML.load(f.read) }
          # If a file was consisted comments only, it may parse as an Array.
          h = nil unless h.is_a? Hash
        end
      when Hash
        h = config_file
      end
      h ||= {}

      @name = h['name'] || h[:name] || NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleExecutable")
      @database_dir = search_directory_for h['database_dir'] || h[:database_dir]
      @database_name = h['database_name'] || h[:database_name] || name
      @model_name = h['model_name'] || h[:model_name] || name
      @icloud = begin
        v = h['icloud'] || h[:icloud]
        v ? v.boolValue : false
      end
      @icloud_container = h['icloud_container'] || h[:icloud_container]
    end

    def database_url
      dir = NSSearchPathForDirectoriesInDomains(database_dir, NSUserDomainMask, true).last
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


    private

      def search_directory_for dir_name
        supported_dirs = {
          "NSDocumentDirectory" => NSDocumentDirectory,
          :NSDocumentDirectory => NSDocumentDirectory,
          "NSApplicationSupportDirectory" => NSApplicationSupportDirectory,
          :NSApplicationSupportDirectory => NSApplicationSupportDirectory,
        }
        supported_dirs[dir_name] || NSDocumentDirectory
      end

  end

end


