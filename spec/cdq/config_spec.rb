

module CDQ

  describe "CDQ Config" do

    before do
      @bundle_name = NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName")
    end

    it "sets default values when no config file present" do
      config = CDQConfig.new(nil)
      config.name.should == @bundle_name
      config.database_name.should == config.name
      config.model_name.should == config.name
    end

    it "can initialize values from a hash" do
      config = CDQConfig.new(name: "foo")
      config.name.should == "foo"
      config.database_name.should == "foo"
      config.model_name.should == "foo"
    end

    it "can override the default name" do
      cf_file = File.join(NSBundle.mainBundle.bundlePath, "cdq.yml")
      yaml_to_file(cf_file, name: "foo")
      config = CDQConfig.new(cf_file)
      config.name.should == "foo"
      config.database_name.should == "foo"
      config.model_name.should == "foo"
      File.unlink(cf_file)
    end

    it "can override database_name specifically" do
      cf_file = File.join(NSBundle.mainBundle.bundlePath, "cdq.yml")
      yaml_to_file(cf_file, database_name: "foo")
      config = CDQConfig.new(cf_file)
      config.name.should == @bundle_name
      config.database_name.should == "foo"
      config.model_name.should == config.name
      File.unlink(cf_file)
    end

    it "can override model_name specifically" do
      cf_file = File.join(NSBundle.mainBundle.bundlePath, "cdq.yml")
      yaml_to_file(cf_file, model_name: "foo")
      config = CDQConfig.new(cf_file)
      config.name.should == @bundle_name
      config.database_name.should == config.name
      config.model_name.should == "foo"
      File.unlink(cf_file)
    end

    it "constructs database_url" do
      config = CDQConfig.new(nil)
      config.database_url.class.should == NSURL
      config.database_url.path.should =~ %r{Documents/#{@bundle_name}.sqlite$}
    end

    it "constructs model_url" do
      config = CDQConfig.new(nil)
      config.model_url.class.should == NSURL
      config.model_url.path.should =~ %r{#{@bundle_name}_spec.app/#{@bundle_name}.momd$}
    end

    def yaml_to_file(file, hash)
      contents = YAML.dump(hash)
      File.open(file,'w+') { |f| f.write(contents) }
    end

  end

end
