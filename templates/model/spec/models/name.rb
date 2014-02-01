describe '<%= @name_camel_case %>' do

  before do
    class << self
      include CDQ
    end
    cdq.setup
  end

  after do
    cdq.reset!
  end

  it 'should be a <%= @name_camel_case %> entity' do
    <%= @name_camel_case %>.entity_description.name.should == '<%= @name_camel_case %>'
  end
end
