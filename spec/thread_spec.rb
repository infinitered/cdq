describe "multi threading" do

  before do
    class << self
      include CDQ
    end
  end
  
  it 'should word background' do
    Author.count.should == 0
    
    parent = cdq.contexts.current
    Dispatch::Queue.concurrent.sync do
      cdq.contexts.push(parent)
      cdq.contexts.new(NSConfinementConcurrencyType) do
        Author.create(name:"George")
        @result = cdq.save
      end
    end
    Author.count.should == 1
  end

end
