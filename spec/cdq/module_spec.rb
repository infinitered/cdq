
module CDQ

  describe "CDQ Magic Method" do

    before do
      class << Author
        include CDQ
      end

      class << self
        include CDQ
      end
    end

    it "wraps an NSManagedObject class in a CDQTargetedQuery" do
      cdq(Author).class.should == CDQTargetedQuery
    end

    it "treats a string as an entity name and returns a CDQTargetedQuery" do
      cdq('Author').class.should == CDQTargetedQuery
    end

    it "treats a symbol as an attribute key and returns a CDQPartialPredicate" do
      cdq(:name).class.should == CDQPartialPredicate
    end

    it "passes through existing CDQObjects unchanged" do
      query = CDQQuery.new 
      cdq(query).should == query
    end

    it "uses 'self' if no object passed in" do
      Author.cdq.class.should == CDQTargetedQuery
    end

    it "works with entities that do not have a specific implementation class" do
      cdq('Publisher').class.should == CDQTargetedQuery
    end

  end

end

