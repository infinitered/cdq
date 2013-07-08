
module CDQ

  describe "CDQ Model Manager" do

    it "can be created with an explicit name" do
      @mm = CDQModelManager.new(name: "CDQ")
      @mm.current.class.should == NSManagedObjectModel
    end

    it "can be created with a default name" do
      @mm = CDQModelManager.new
      @mm.current.class.should == NSManagedObjectModel
    end

  end

end

