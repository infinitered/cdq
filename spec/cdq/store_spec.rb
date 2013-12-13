
module CDQ

  describe "CDQ Store Manager" do

    before do
      CDQ.cdq.setup
      @sm = CDQStoreManager.new(model: CDQ.cdq.models.current)
    end

    after do
      CDQ.cdq.reset!
    end

    it "can set up a store coordinator with default name" do
      @sm.current.should != nil
      @sm.current.class.should == NSPersistentStoreCoordinator
    end

    it "rejects attempt to create without a valid model" do
      should.raise do
        CDQStoreManager.new(model: nil).current
      end
    end

    it "permits setting custom store manager" do
      should.not.raise do
        nsm = CDQStoreManager.new(model: nil)
        nsm.current = @sm.current
        nsm.current
      end
    end

  end

end
