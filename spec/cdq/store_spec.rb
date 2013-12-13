
module CDQ

  describe "CDQ Store Manager" do

    before do
      CDQ.cdq.setup
      @sm = CDQStoreManager.new(model_manager: CDQ.cdq.models)
    end

    after do
      CDQ.cdq.reset!
    end

    it "can set up a store coordinator with default name" do
      @sm.current.should != nil
      @sm.current.class.should == NSPersistentStoreCoordinator
    end

    it "rejects attempt to create without a valid model" do
      c = CDQConfig.new(name: "foo")
      mm = CDQModelManager.new(config: c)
      sm = CDQStoreManager.new(config: c, model_manager: mm)
      should.raise do
        sm.current
      end
    end

    it "permits setting custom store manager" do
      nsm = CDQStoreManager.new(model: nil)
      should.not.raise do
        nsm.current = @sm.current
        nsm.current
      end
    end

  end

end
