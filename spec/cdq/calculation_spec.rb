module CDQ
  describe "CDQ Calculation Methods" do

    before do
      CDQ.cdq.setup

      class << self
        include CDQ
      end
      
      @fees = [1.0, 2.0, 3.0]
      @author_foo = Author.create(name: 'foo', fee: @fees[0])
      Author.create(name: 'foo', fee: @fees[1])
      Author.create(name: 'bar', fee: @fees[2])
      
      @lengths = [1, 2, 3, 4]
      @author_foo.articles.create(title: 'foo', body: 'bar', length: @lengths[0])
      @author_foo.articles.create(title: 'foo', body: 'bar', length: @lengths[1])
      Article.create(title: 'foo', body: 'bar', length: @lengths[2])
      Article.create(title: 'foo', body: 'bar', length: @lengths[3])
      cdq.save(always_wait: true)
    end

    after do
      CDQ.cdq.reset!
    end

    it "can calculate sum of float values" do
      Author.sum(:fee).should == @fees.inject(:+)
    end

    it "can calculate average of float values" do
      Author.average(:fee).should == (@fees.inject(:+).to_f / @fees.size)
    end

    it "can calculate min of float values" do
      Author.min(:fee).should == @fees[0]
      Author.minimum(:fee).should == @fees[0]
    end

    it "can calculate max of float values" do
      Author.max(:fee).should == @fees[2]
      Author.maximum(:fee).should == @fees[2]
    end

    it "can calculate sum of integer values" do
      Article.sum(:length).should == @lengths.inject(:+)
    end

    it "can do calculation with chained query" do
      Author.where(:name).eq('foo').calculate(:sum, :fee).should == @fees[0..1].inject(:+)
    end

    it "can do calculation on relations" do
      @author_foo.articles.calculate(:sum, :length).should == @lengths[0..1].inject(:+)
    end
  end
end
