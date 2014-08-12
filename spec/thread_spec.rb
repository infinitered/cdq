describe "multi threading" do
  tests UIViewController

  before do
    class << self
      include CDQ
    end
  end
  
  it 'should word background' do
    Author.count.should == 0
    
    parent = cdq.contexts.current
    Dispatch::Queue.concurrent.async do
      cdq.contexts.new(NSConfinementConcurrencyType, parent) do
        context = cdq.contexts.current
        @parent = context.parentContext
        Author.create(name:"George")
        @result = cdq.save
      end
    end
    
    wait 0.3 do
      Author.count.should == 1
    end
  end

end
