
module CDQ
  describe "CDQ Object Proxy" do

    before do
      class << self
        include CDQ
      end

      cdq.setup

      @author = Author.create(name: "Stephen King")
      @article = Article.create(title: "IT", author: @author)

      @op = CDQObjectProxy.new(@author)
    end

    after do
      cdq.reset!
    end

    it "wraps an NSManagedObject" do
      @op.get.should == @author
    end

    it "can forward messages to its object" do
      @op.name.should == @author.name
    end

    it "wraps relations in CDQRelationshipQuery objects" do
      @op.articles.class.should == CDQRelationshipQuery
      @op.articles.first.should == @article
    end

    it "considers itself == to its target" do
      @op.should == @author
    end

  end
end
