
module CDQ

  describe "CDQ Relationship Query" do

    before do

      class << self
        include CDQ
      end

      cdq.setup

      @author = Author.create(name: "eecummings")
      @article1 = Article.create(body: "", published: true, publishedAt: Time.local(1922), title: "The Enormous Room")
      @author.articles.addObject(@article1)

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
  end

end

