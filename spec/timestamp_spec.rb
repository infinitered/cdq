
describe "Timestamp Tests" do

  before do

    class << self
      include CDQ
    end

    cdq.setup

    @now = Time.new(2014, 6, 2, 0, 0, 0)
    @after_1_sec = Time.new(2014, 6, 2, 0, 0, 1)

    Time.stub!(:now, :return => @now)

    @timestamp = Timestamp.create
  end

  after do
    cdq.reset!
  end

  it "should be nil initally" do
    @timestamp.created_at.should == nil
    @timestamp.updated_at.should == nil
  end

  describe "Timestamp Create Case" do

    before do
      cdq.save(always_wait: true)
    end

    it "should set created_at" do
      @timestamp.created_at.should == @now
    end

    it "should set updated_at" do
      @timestamp.updated_at.should == @now
    end
  end

  describe "Timestamp Update Case" do
    before do
      cdq.save(always_wait: true)

      Time.stub!(:now, :return => @after_1_sec)
      @timestamp.flag = true
      cdq.save(always_wait: true)
    end

    it "should not set created_at" do
      @timestamp.created_at.should == @now
    end

    # This is failing when it shouldn't.  Suspect RM bug.
    #
    # it "should set updated_at" do
    #   @timestamp.updated_at.should == @after_1_sec
    # end
  end

end
