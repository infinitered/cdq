
module CDQ

  describe "CDQ Model Manager" do

    it "can be created with a default name" do
      @mm = CDQModelManager.new
      @mm.current.class.should == NSManagedObjectModel
    end

    it 'should log models' do
      @mm = CDQModelManager.new
      @mm.log(:string).should != nil
    end

  end

end

