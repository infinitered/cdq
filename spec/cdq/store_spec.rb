
module CDQ

  describe "CDQ Store Manager" do

    before do
      CDQ.cdq.setup
    end

    after do
      CDQ.cdq.reset!
    end

    it "can set up a store coordinator" do
      @sm = CDQStoreManager.new(name: "CDQApp", model: CDQ.cdq.models.current)
      @sm.current.should != nil
      @sm.current.class.should == NSPersistentStoreCoordinator
    end

    it "can set up a store coordinator with default name" do
      @sm = CDQStoreManager.new(model: CDQ.cdq.models.current)
      @sm.current.should != nil
      @sm.current.class.should == NSPersistentStoreCoordinator
    end

  end

end
