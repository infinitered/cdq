
module CDQ

  describe "CDQ Context Manager" do

    before do
      CDQ.cdq.setup

      class << self
        include CDQ
      end
    end

    after do
      CDQ.cdq.reset!
    end


    before do
      @cc = CDQContextManager.new(store_coordinator: cdq.stores.current)
      @context = NSManagedObjectContext.alloc.initWithConcurrencyType(NSPrivateQueueConcurrencyType)
    end

    it "can push a NSManagedObjectContext onto its stack" do
      @cc.push(@context)
      @cc.current.should == @context
      @cc.all.should == [@context]
    end

    it "can pop a NSManagedObjectContext off its stack" do
      @cc.push(@context)
      @cc.pop.should == @context
      @cc.current.should == nil
      @cc.all.should == []
    end

    it "pushes temporarily if passed a block" do
      @cc.push(@context) do
        @cc.current.should == @context
      end
      @cc.current.should == nil
    end

    it "pops temporarily if passed a block" do
      @cc.push(@context)
      @cc.pop do
        @cc.current.should == nil
      end
      @cc.current.should == @context
    end

    it "can create a new context and push it to the top of the stack" do
      first = @cc.new(NSPrivateQueueConcurrencyType)
      @cc.current.should.not == nil
      @cc.current.concurrencyType.should == NSPrivateQueueConcurrencyType
      @cc.current.parentContext.should == nil
      @cc.current.persistentStoreCoordinator.should.not == nil
      @cc.new(NSMainQueueConcurrencyType)
      @cc.current.should.not == nil
      @cc.current.concurrencyType.should == NSMainQueueConcurrencyType
      @cc.current.parentContext.should == first
    end

    it "saves all contexts" do
      root = @cc.new(NSPrivateQueueConcurrencyType)
      main = @cc.new(NSMainQueueConcurrencyType)
      root_saved = false
      main_saved = false
      root.stub!(:save) { root_saved = true }
      main.stub!(:save) { main_saved = true }
      @cc.save

      root_saved.should == true
      main_saved.should == true
    end

  end

end
