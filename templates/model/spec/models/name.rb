describe '<%= @name_camel_case %>' do

  before do
    include CDQ
    cdq.setup
  end

  after do
    cdq.reset!
  end

  it 'should be a <%= @name_camel_case %> entity'
    <%= @name_camel_case %>.entity_description.name.should == '<%= @name_camel_case %>'
  end
end
