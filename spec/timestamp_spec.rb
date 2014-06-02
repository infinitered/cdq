
describe "Timestamp Tests" do

  before do

    class << self
      include CDQ
    end

    cdq.setup
  end

  after do
    cdq.reset!
  end

  it "should be nil initally" do
    timestamp = Timestamp.create
    [timestamp.created_at, timestamp.updated_at].should == [nil, nil]
  end

  it "should set" do
    now = Time.new(2014, 6, 2, 0, 0, 0)
    Time.stub!(:now, :return => now)
    timestamp = Timestamp.create
    cdq.save(always_wait: true)
    [timestamp.created_at, timestamp.updated_at].should == [now, now]
  end

  it "should set updated_at only" do
    now = Time.new(2014, 6, 2, 0, 0, 0)
    Time.stub!(:now, :return => now)
    timestamp = Timestamp.create
    cdq.save(always_wait: true)

    after_1_sec = Time.new(2014, 6, 2, 0, 0, 1)
    Time.stub!(:now, :return => after_1_sec)
    timestamp.flag = true
    cdq.save(always_wait: true)
    [timestamp.created_at, timestamp.updated_at].should == [now, after_1_sec]
  end

end
