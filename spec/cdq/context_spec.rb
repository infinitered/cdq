
module CDQ

  describe "CDQ Context Manager" do

    before do
      class << self
        include CDQ
      end
    end

    after do
      CDQ::Deprecation.silence_deprecation = false
      CDQ.cdq.reset!
    end


    before do
      @cc = CDQContextManager.new(store_manager: cdq.stores)
      @context = NSManagedObjectContext.alloc.initWithConcurrencyType(NSPrivateQueueConcurrencyType)
    end

    it "should raise an exception if not given a store coordinator" do
      c = CDQConfig.new(name: "foo")
      mm = CDQModelManager.new(config: c)
      sm = CDQStoreManager.new(config: c, model_manager: mm)

      cc = CDQContextManager.new(store_manager: sm)


      should.raise(RuntimeError) do
        cc.push(NSPrivateQueueConcurrencyType)
      end
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

    it "sets a default context if used for the first time" do
      @cc.current.should != nil
    end

    it "pushes temporarily if passed a block" do
      @cc.push(NSMainQueueConcurrencyType)
      @cc.pop
      @cc.current.should == nil
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
      first = @cc.push(NSPrivateQueueConcurrencyType)
      @cc.current.should == first
      @cc.current.persistentStoreCoordinator.should.not == nil
      second = @cc.push(NSMainQueueConcurrencyType)
      @cc.current.should == second
      @cc.current.parentContext.should == first
    end

    # REMOVE:1.1
    it "can create a new context and push it to the top of the stack (deprecated)" do
      CDQ::Deprecation.silence_deprecation = true
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

    it "can create a new context WITHOUT pushing it to the top of the stack" do
      first = @cc.create(NSPrivateQueueConcurrencyType)
      first.class.should == NSManagedObjectContext
      @cc.current.should == nil
    end

    it "saves all contexts" do
      root = @cc.push(NSPrivateQueueConcurrencyType)
      main = @cc.push(NSMainQueueConcurrencyType)
      root_saved = false
      main_saved = false
      root.stub!(:save) { root_saved = true }
      main.stub!(:save) { main_saved = true }
      @cc.save(always_wait: true)

      root_saved.should == true
      main_saved.should == true
    end

  end

end
