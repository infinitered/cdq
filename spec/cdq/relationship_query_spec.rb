
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
      @rq = nil
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

    it "can add objects to the relationship" do
      article = Article.create(body: "bank")
      @author.articles.add(article)
      @author.articles.where(body: "bank").first.should == article
      article.author.should == @author

      ram = Writer.create(name: "Ram Das")
      ram.spouses.add cdq('Spouse').create
      ram.spouses << cdq('Spouse').create

      ram.spouses.count.should == 2
      ram.spouses.first.writers.count.should == 1
    end

    it "can remove a relationship and persist it" do
      ram = Writer.create(name: "Ram Das")
      ram.spouses.add cdq('Spouse').create(name: "First Spouse")
      ram.spouses << cdq('Spouse').create
      ram.spouses.count.should == 2
      cdq.save(always_wait: true)

      cdq.contexts.reset!; ram = nil; cdq.setup
      ram = Writer.where(:name).eq("Ram Das").first
      ram.spouses.count.should == 2
      first_spouse = ram.spouses.first
      first_spouse.writers.count.should == 1
      ram.spouses.remove(first_spouse)
      ram.spouses.count.should == 1
      first_spouse.writers.count.should == 0
      cdq.save(always_wait: true)

      cdq.contexts.reset!; ram = nil; cdq.setup
      ram = Writer.where(:name).eq("Ram Das").first
      ram.spouses.count.should == 1
      ex_spouse = cdq('Spouse').where(:name).eq("First Spouse").first
      ex_spouse.writers.count.should == 0
    end

    it "can remove objects from the relationship" do
      article = Article.create(title: "thing", body: "bank")
      cdq.save
      @author.articles.count.should == 1
      @author.articles.remove(@article1)
      cdq.save
      @author.articles.count.should == 0
    end

    it "iterates over ordered sets correctly" do
      writer = Writer.create
      two = cdq('Spouse').create(name: "1")
      three = cdq('Spouse').create(name: "2")
      one = writer.spouses.create(name: "3")
      writer.spouses << two
      writer.spouses << three
      writer.spouses.map(&:name).should == ["3", "1", "2"]
      writer.spouses.array.map(&:name).should == ["3", "1", "2"]
    end

  end

end

