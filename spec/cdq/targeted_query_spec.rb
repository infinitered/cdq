
module CDQ
  describe "CDQ Targeted Query" do

    before do
      CDQ.cdq.setup
    end

    after do
      CDQ.cdq.reset!
    end

    it "reflects a base state" do
      tq = CDQTargetedQuery.new(Author.entity_description, Author)
      tq.count.should == 0
      tq.array.should == []
    end

    it "can count objects" do
      tq = CDQTargetedQuery.new(Author.entity_description, Author)
      Author.create(name: "eecummings")
      tq.count.should == 1
      Author.create(name: "T. S. Eliot")
      tq.count.should == 2
      tq.size.should == 2
      tq.length.should == 2
    end

    it "can fetch objects" do
      tq = CDQTargetedQuery.new(Author.entity_description, Author)
      eecummings = Author.create(name: "eecummings")
      tseliot = Author.create(name: "T. S. Eliot")
      tq.array.sort_by(&:name).should == [tseliot, eecummings]
    end

    it "can create objects" do
      tq = CDQTargetedQuery.new(Author.entity_description, Author)
      maya = tq.create(name: "maya angelou")
      tq.where(:name).eq("maya angelou").first.should == maya
    end

    it 'should log query' do
      Article.create(title: "thing", body: "thing", author: Author.create(name: "eecummings"))
      Author.log(:string).should != nil
      Article.log(:string).should != nil
    end

  end

  describe "CDQ Targeted Query with data" do

    before do
      CDQ.cdq.setup

      class << self
        include CDQ
      end

      @tq = cdq(Author)
      @eecummings = Author.create(name: "eecummings")
      @tseliot = Author.create(name: "T. S. Eliot")
      @dante = Author.create(name: "dante")
      cdq.save
    end

    after do
      CDQ.cdq.reset!
    end

    it "performs a sorted fetch" do
      @tq.sort_by(:name).array.should == [@tseliot, @dante, @eecummings]
    end

    it "performs a limited fetch" do
      @tq.sort_by(:name).limit(1).array.should == [@tseliot]
    end

    it "performs an offset fetch" do
      @tq.sort_by(:name).offset(1).array.should == [@dante, @eecummings]
      @tq.sort_by(:name).offset(1).limit(1).array.should == [@dante]
    end

    it "performs a restricted search" do
      @tq.where(:name).eq("dante").array.should == [@dante]
    end

    it "gets the first entry" do
      @tq.sort_by(:name).first.should == @tseliot
    end

    it "gets the first n entries" do
      result = @tq.sort_by(:name).first(2)

      result.class.should == Array
      result.should == [@tseliot, @dante]
    end

    it "gets the last entry" do
      @tq.sort_by(:name).last.should == @eecummings
    end

    it "gets the last n entries" do
      result = @tq.sort_by(:name).last(2)

      result.class.should == Array
      result.should == [@dante, @eecummings]
    end

    it "gets entries by index" do
      @tq.sort_by(:name)[0].should == @tseliot
      @tq.sort_by(:name)[1].should == @dante
      @tq.sort_by(:name)[2].should == @eecummings
    end

    it "can iterate over entries" do
      entries = [@tseliot, @dante, @eecummings]

      @tq.sort_by(:name).each do |e|
        e.should == entries.shift
      end
    end

    it "can map over entries" do
      entries = [@tseliot, @dante, @eecummings]

      @tq.sort_by(:name).map { |e| e }.should == entries
    end

    it "can create a named scope" do
      @tq.scope :two_sorted_by_name, @tq.sort_by(:name).limit(2)
      @tq.two_sorted_by_name.array.should == [@tseliot, @dante]
    end

    it "can create a dynamic named scope" do
      tq = cdq(Article)
      a = tq.create(publishedAt: Time.local(2001))
      b = tq.create(publishedAt: Time.local(2002))
      c = tq.create(publishedAt: Time.local(2003))
      d = tq.create(publishedAt: Time.local(2004))

      tq.scope :date_span { |start_date, end_date| cdq(:publishedAt).lt(end_date).and.ge(start_date) }
      tq.date_span(Time.local(2002), Time.local(2004)).sort_by(:publishedAt).array.should == [b, c]
      Article.published_since(Time.local(2003)).sort_by(:publishedAt).array.should == [c, d]
    end

    it "can create a scope with the same name for two entities without clashing" do
      a = article.create(publishedAt: Time.local(2001))

      Article.clashing.array.should == [a]
      Author.clashing.array.should == [@eecummings]
    end
  end
end
