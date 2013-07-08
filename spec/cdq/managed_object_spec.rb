
module CDQ
  describe "CDQ Managed Object" do

    before do
      CDQ.cdq.setup

      class << self
        include CDQ
      end
    end

    after do
      CDQ.cdq.reset!
    end

    it "provides a cdq class method" do
      Writer.cdq.class.should == CDQTargetedQuery
    end

    it "has a where method" do
      Writer.where(:name).eq('eecummings').class.should == CDQTargetedQuery
    end

    it "has a sort_by method" do
      Writer.sort_by(:name).class.should == CDQTargetedQuery
    end

    it "has a first method" do
      eec = cdq(Writer).create(name: 'eecummings')
      Writer.first.should == eec
    end

    it "has an all method" do
      eec = cdq(Writer).create(name: 'eecummings')
      Writer.all.array.should == [eec]
    end

    it "can destroy itself" do
      eec = cdq(Writer).create(name: 'eecummings')
      eec.destroy
      Writer.all.array.should == []
    end

    it "works with entities that do not have a specific implementation class" do
      rh = cdq('Publisher').create(name: "Random House")
      cdq('Publisher').where(:name).include("Random").first.should == rh
      rh.destroy
      cdq.save
      cdq('Publisher').where(:name).include("Random").first.should == nil
    end

    describe "CDQ Managed Object scopes" do

      before do
        class Writer
          scope :eecummings, where(:name).eq('eecummings')
          scope :edgaralpoe, where(:name).eq('edgar allen poe')
        end
        @eec = cdq(Writer).create(name: 'eecummings')
        @poe = cdq(Writer).create(name: 'edgar allen poe')
      end

      it "defines scopes straight on the class object" do
        Writer.eecummings.array.should == [@eec]
        Writer.edgaralpoe.array.should == [@poe]
      end
        
      it "also defines scopes on the cdq object" do
        Writer.cdq.eecummings.array.should == [@eec]
        Writer.cdq.edgaralpoe.array.should == [@poe]
      end
    end
  end
end
