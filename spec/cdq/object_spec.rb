
module CDQ

  describe "CDQ Object" do

    before do
      class << self
        include CDQ
      end

      cdq.setup
    end

    after do
      cdq.reset!
    end

    it "has a contexts method" do
      cdq.contexts.class.should == CDQContextManager
    end

    it "has a stores method" do
      cdq.stores.class.should == CDQStoreManager
    end

    it "has a models method" do
      cdq.models.class.should == CDQModelManager
    end

    it "can override model" do
      model = cdq.models.current

      cdq.reset!

      cdq.setup(model: model)
      cdq.models.current.should == model
    end

    it "can override store" do
      store = cdq.stores.current

      cdq.reset!

      cdq.setup(store: store)
      cdq.stores.current.should == store
    end

    it "can override context" do
      context = cdq.contexts.current

      cdq.reset!

      cdq.setup(context: context)
      cdq.contexts.current.should == context
    end

    it "can open different database without deleting the previous one" do
      org_database_url = CDQConfig.default.database_url.path
      File.exist?(org_database_url).should == true
      cdq.close

      config = CDQConfig.new(name: "foo")
      File.exist?(config.database_url.path).should == false
      
      cdq.setup(config: config)

      CDQConfig.default.should == config
      File.exist?(config.database_url.path).should == true
      File.exist?(org_database_url).should == true
    end

  end

end
