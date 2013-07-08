
module CDQ

  describe "CDQ Object" do

    before do
      CDQ.cdq.setup

      class << self
        include CDQ
      end
    end

    after do
      CDQ.cdq.reset!
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

  end

end
