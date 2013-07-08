
module CDQ
  describe "CDQ Query" do

    before do
      @query = CDQQuery.new
    end

    it "creates a query with a simple true predicate" do
      @query.predicate.should == nil
      @query.limit.should == nil
      @query.offset.should == nil
    end

    it "can set a limit on a query" do
      @query = CDQQuery.new(limit: 1)
      @query.limit.should == 1
      @query.offset.should == nil
    end

    it "can set a offset on a query" do
      @query = CDQQuery.new(offset: 1)
      @query.limit.should == nil
      @query.offset.should == 1
    end

    it "can 'and' itself with another query" do
      @query = CDQQuery.new(limit: 1, offset: 1)
      @other = CDQQuery.new(predicate: NSPredicate.predicateWithValue(false), limit: 2)
      @compound = @query.and(@other)
      @compound.predicate.should == NSPredicate.predicateWithValue(false)
      @compound.limit.should == 2
      @compound.offset.should == 1
    end

    it "can 'and' itself with an NSPredicate" do
      @compound = @query.and(NSPredicate.predicateWithValue(false))
      @compound.predicate.should == NSPredicate.predicateWithValue(false)
    end

    it "can 'and' itself with a string-based predicate query" do
      query = @query.where(:name).begins_with('foo')
      compound = query.and("name != %@", 'fool')
      compound.predicate.predicateFormat.should == 'name BEGINSWITH "foo" AND name != "fool"'
    end

    it "can 'and' itself with a hash" do
      compound = @query.and(name: "foo", fee: 2)
      compound.predicate.predicateFormat.should == 'name == "foo" AND fee == 2'
    end

    it "starts a partial predicate when 'and'-ing a symbol" do
      ppred = @query.and(:name)
      ppred.class.should == CDQPartialPredicate
      ppred.key.should == :name
    end

    it "can 'or' itself with another query" do
      @query = CDQQuery.new(limit: 1, offset: 1)
      @other = CDQQuery.new(predicate: NSPredicate.predicateWithValue(false), limit: 2)
      @compound = @query.or(@other)
      @compound.predicate.should == NSPredicate.predicateWithValue(false)
      @compound.limit.should == 2
      @compound.offset.should == 1
    end

    it "can 'or' itself with an NSPredicate" do
      @compound = @query.or(NSPredicate.predicateWithValue(false))
      @compound.predicate.should == NSPredicate.predicateWithValue(false)
    end

    it "can 'or' itself with a string-based predicate query" do
      query = @query.where(:name).begins_with('foo')
      compound = query.or("name != %@", 'fool')
      compound.predicate.predicateFormat.should == 'name BEGINSWITH "foo" OR name != "fool"'
    end

    it "can sort by a key" do
      @query.sort_by(:name).sort_descriptors.should == [
        NSSortDescriptor.sortDescriptorWithKey('name', ascending: true)
      ]
    end

    it "can sort descending" do
      @query.sort_by(:name, :desc).sort_descriptors.should == [
        NSSortDescriptor.sortDescriptorWithKey('name', ascending: false)
      ]
    end

    it "can chain sorts" do
      @query.sort_by(:name).sort_by(:title).sort_descriptors.should == [
        NSSortDescriptor.sortDescriptorWithKey('name', ascending: true),
        NSSortDescriptor.sortDescriptorWithKey('title', ascending: true)
      ]
    end

    it "reuses the previous key when calling 'and' or 'or' with no arguments" do
      compound = @query.where(:name).begins_with('foo').and.ne('fool')
      compound.predicate.predicateFormat.should == 'name BEGINSWITH "foo" AND name != "fool"'

      compound = @query.where(:name).begins_with('foo').or.eq('loofa')
      compound.predicate.predicateFormat.should == 'name BEGINSWITH "foo" OR name == "loofa"'
    end

    it "handles complex examples" do
      query1 = CDQQuery.new
      query2 = query1.where(CDQQuery.new.where(:name).ne('bob', NSCaseInsensitivePredicateOption).or(:amount).gt(42).sort_by(:name))
      query3 = query1.where(CDQQuery.new.where(:enabled).eq(true).and(:'job.title').ne(nil).sort_by(:amount, :desc))

      query4 = query3.where(query2)
      query4.predicate.predicateFormat.should == '(enabled == 1 AND job.title != nil) AND (name !=[c] "bob" OR amount > 42)'
      query4.sort_descriptors.should == [
        NSSortDescriptor.alloc.initWithKey('amount', ascending:false),
        NSSortDescriptor.alloc.initWithKey('name', ascending:true)
      ]
    end

    it "can make a new query with a new limit" do:w
    @query = CDQQuery.new
    new_query = @query.limit(1)

    new_query.limit.should == 1
    new_query.offset.should == nil
  end

end
end
