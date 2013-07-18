
describe "Integration Tests" do

  before do

    class << self
      include CDQ
    end

    cdq.setup

    @author = Author.create(name: "Albert Einstein")

    @fundamentals = @author.articles.create(body: "...", published: true, publishedAt: Time.local(1940),
                                            title: "Considerations concering the fundamentals of theoretical physics")

    @gravitation = @author.articles.create(body: "...", published: true, publishedAt: Time.local(1937),
                                           title: "On gravitational waves")

    @fcite = @fundamentals.citations.create(journal: "Science", timestamp: Time.local(1940))
    @gcite = @gravitation.citations.create(journal: "Nature", timestamp: Time.local(1941))

    cdq.save(always_wait: true)
  end

  after do
    cdq.reset!
  end

  it "should be able to combine simple queries" do
    @author.articles.count.should == 2
    @author.articles.first.citations.count.should == 1
    @author.articles.where(:title).matches('.*fundamentals.*').first.citations.array.should == [@fcite]

    @gcite.article.author.should == @author
  end

end
