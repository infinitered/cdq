
module CDQ

  describe "CDQ Relationship Query" do

    before do

      class << self
        include CDQ
      end

      cdq.setup

      @author = Author.create(name: "eecummings")
      @article1 = @author.articles.create(author: @author, body: "", published: true, publishedAt: Time.local(1922), title: "The Enormous Room")

      cdq.save(always_wait: true)

    end

    after do
      cdq.reset!
    end

    it "performs queries against the target entity" do
      @rq = CDQRelationshipQuery.new(@author, 'articles')
      @rq.first.should != nil
      @rq.first.class.should == Article_Article_
    end

    it "should be able to use named scopes" do
      cdq(@author).articles.all_published.array.should == [@article1]
    end

    it "can handle many-to-many correctly" do
      ram = Writer.create(name: "Ram Das")
      first = ram.spouses.create
      second = ram.spouses.create
      ram.spouses.array.should == [first, second]
      cdq(first).writers.array.should == [ram]
      cdq(second).writers.array.should == [ram]
      cdq(first).writers.where(:name).contains("o").array.should == []
      cdq(first).writers.where(:name).contains("a").array.should == [ram]
    end

  end

end

