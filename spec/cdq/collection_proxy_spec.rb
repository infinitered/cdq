
module CDQ
  describe "CDQ Collection Proxy" do
    before do
      class << self
        include CDQ
      end

      cdq.setup

      @author = Author.create(name: "Stephen King")
      @articles = [
        Article.create(title: "The Gunslinger", author: @author),
        Article.create(title: "The Drawing of the Three", author: @author),
        Article.create(title: "The Waste Lands", author: @author),
        Article.create(title: "Wizard and Glass", author: @author),
        Article.create(title: "The Wolves of the Calla", author: @author),
        Article.create(title: "Song of Susannah", author: @author),
        Article.create(title: "The Dark Tower", author: @author)
      ]

      @cp = CDQCollectionProxy.new(@articles, @articles.first.entity)
    end

    after do
      cdq.reset!
    end

    it "wraps an array of objects" do
      @cp.get.should == @articles
    end

    it "gets the first object" do
      @cp.first.should == @articles.first
    end

    it "gets the first n objects" do
      @cp.first(5).should == @articles.first(5)
      @cp.first(2).should == [@articles[0], @articles[1]]
      @cp.first(3).should == [@articles[0], @articles[1], @articles[2]]
    end

    it "gets the last object" do
      @cp.last.should == @articles.last
    end

    it "gets the last n objects" do
      @cp.last(5).should == @articles.last(5)
      @cp.last(2).should == [@articles[5], @articles[6]]
      @cp.last(3).should == [@articles[4], @articles[5], @articles[6]]
    end

    it "can use a where query" do
      q = @cp.where(:title).contains(" of ").sort_by(:title)
      q.count.should == 3
      q.array.should == [1,4,5].map { |i| @articles[i] }.sort_by(&:title)
    end

    it "behaves properly when given an empty set" do
      cp = CDQCollectionProxy.new([], @articles.first.entity)
      cp.get.should == []
      cp.count.should == 0
      q = cp.or(:title).contains(" of ").sort_by(:title)
      q.count.should == 3
      q.array.should == [1,4,5].map { |i| @articles[i] }.sort_by(&:title)
    end

    it "allows you to grab count with size and length aliases" do
      @author.articles.count.should == 7
      @author.articles.size.should == 7
      @author.articles.length.should == 7
    end

  end
end

