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

    it "returns the attributes of the entity" do
      Writer.attribute_names.should.include(:name)
    end

    it "does not crash when respond_to? called on CDQManagedObject directly" do
      should.not.raise do
        CDQManagedObject.respond_to?(:foo)
      end
    end

    it "can destroy all instances of itself" do
      cdq(Writer).create(name: 'Dean Kuntz')
      cdq(Writer).create(name: 'Stephen King')
      cdq(Writer).create(name: 'Tom Clancy')
      Writer.count.should == 3

      Writer.destroy_all!
      Writer.count.should == 0
    end

    it "works with entities that do not have a specific implementation class" do
      rh = cdq('Publisher').create(name: "Random House")
      cdq.save
      cdq('Publisher').where(:name).include("Random").first.should == rh
      rh.destroy
      cdq.save
      cdq('Publisher').where(:name).include("Random").first.should == nil
    end

    it "returns relationship sets which can behave like CDQRelationshipQuery objects" do
      eec = Author.create(name: 'eecummings')
      art = eec.articles.create(title: 'something here')
      eec.articles.sort_by(:title).first.should == art
    end

    it "returns a hash of attributes" do
      john = cdq(Writer).create(fee: 21.2, name: 'John Grisham')
      john.attributes.should == { "fee" => 21.2, "name" => 'John Grisham' }
    end

    describe "respond_to?" do

      before do
        @art = Article.new
      end

      it "works with setters" do
        @art.respond_to?(:"title=").should == true
      end

    end

    describe "CDQ Managed Object scopes" do

      before do
        class Writer
          scope :eecummings, where(:name).eq('eecummings')
          scope :edgaralpoe, cdq(:name).eq('edgar allen poe')
          scope :by_name { |name| cdq(:name).eq(name) }
        end
        @eec = cdq(Writer).create(name: 'eecummings')
        @poe = cdq(Writer).create(name: 'edgar allen poe')
      end

      it "defines scopes straight on the class object" do
        Writer.eecummings.array.should == [@eec]
        Writer.edgaralpoe.array.should == [@poe]
      end

      it "also defines scopes on the cdq object" do
        cdq('Writer').eecummings.array.should == [@eec]
        cdq('Writer').edgaralpoe.array.should == [@poe]
      end

      describe "CDQ Managed Object dynamic scopes" do

        class Writer
          scope :by_name { |name| cdq(:name).eq(name) }
        end

        it "uses the variable you passed in" do
          Writer.by_name('eecummings').array.should == [@eec]
          Writer.by_name('edgar allen poe').array.should == [@poe]
        end
      end
    end
  end
end
