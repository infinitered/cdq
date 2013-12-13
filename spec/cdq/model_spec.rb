
module CDQ

  describe "CDQ Model Manager" do

    it "can be created with a default name" do
      @mm = CDQModelManager.new
      @mm.current.class.should == NSManagedObjectModel
    end

  end

end

