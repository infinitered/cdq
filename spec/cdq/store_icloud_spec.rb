module CDQ

  describe "CDQ Store Manager with iCloud" do

    before do
      @sm = CDQStoreManager.new(iCloud:true, container: "blah")
      CDQ.cdq.setup(stores:@sm)
    end

    after do
      CDQ.cdq.reset!
    end

    it "should create store for icloud" do
      @sm.current.should == CDQ.cdq.stores.current
      CDQ.cdq.stores.current.class.should == NSPersistentStoreCoordinator
    end
    
  end

end
