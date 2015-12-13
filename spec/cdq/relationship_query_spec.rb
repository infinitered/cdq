
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

      @article2 = @author.articles.create(author: @author, body: "", published: true, publishedAt: Time.local(1922), title: "The Ginormous Room")
      cdq.save(always_wait: true)

      @article3 = @author.articles.create(author: @author, body: "", published: true, publishedAt: Time.local(1922), title: "The Even Bigger Room")
      cdq.save(always_wait: true)

      @rq = CDQRelationshipQuery.new(@author, 'articles')
    end

    after do
      cdq.reset!
      @rq = nil
    end

    it "performs queries against the target entity" do
      @rq.first.should != nil
      @rq.first.class.should == Article_Article_
      @rq.first.should == @article1
    end

    it "should be able to get the first n of the query" do
      @rq.first(2).should == [@article1, @article2]
      @rq.first(3).should == [@article1, @article2, @article3]
    end

    it "should be able to get the last of the query" do
      @rq.last.should != nil
      @rq.last.class.should == Article_Article_
      @rq.last.should == @article3
    end

    it "should be able to get the last n of the query" do
      @rq.last(2).should == [@article2, @article3]
      @rq.last(3).should == [@article1, @article2, @article3]
    end

    it "should be able to use named scopes" do
      cdq(@author).articles.all_published.array.should == [@article1, @article2, @article3]
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
      @author.articles.count.should == 3
      @author.articles.remove(@article1)
      cdq.save
      @author.articles.count.should == 2
      @author.articles.remove(@article2)
      cdq.save
      @author.articles.count.should == 1
    end

    it "can remove all objects from the relationship without deleting the linked object" do
      Article.count.should == 3
      @author.articles.count.should == 3
      @author.articles.remove_all
      cdq.save
      @author.articles.count.should == 0
      Article.count.should == 3
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

    it "cascades deletions properly" do
      Discussion.destroy_all!
      Message.destroy_all!

      message_count = 20

      discussion = Discussion.create(name: "Test Discussion")

      message_count.times do |i|
        message = Message.create(content: "Message #{i}")
        discussion.messages << message
      end
      cdq.save

      discussion.messages.count.should == message_count
      Message.count.should == message_count

      discussion.destroy
      cdq.save

      Message.count.should == 0
    end

  end

end
