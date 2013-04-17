require_relative '../spec_helper'

describe Syphon::Api::ModelProxy do
  let(:dsl) { Syphon::ResourceDSL }

  let(:resource_set) { dsl.parse(nil) { 
    resource :people do
      fields :id, :first, :last
    end
  } }

  let (:person_proxy) { Syphon::Api::ModelProxy.new_class(resource_set[:people]).new }
  let (:person) { mock_model("Person") }

  before :each do
    person.stub(SyphonTest::PERSON.to_h)
    person.stub(:attributes) { SyphonTest::PERSON.to_h }
  end

  it 'should wrap an instance of a resource' do
    p = person_proxy.wrap(person)
    p.keys.should == [:id, :first, :last]
  end

  it 'should return all resources in the collection' do
    person.class.should_receive(:all) { [person] }
    result = person_proxy.all
    result.size.should == 1
    p = result.first
    p.keys.should == [:id, :first, :last]
    p.should be_a Hash
  end

  it 'should return all resources in the collection filtered by a query' do
    person.class.should_receive(:all) { person.class }
    person.class.should_receive(:where) { person.class }
    person.class.should_receive(:order) { person.class }
    person.class.should_receive(:first) { [person] }
    p = person_proxy.all([:first, { where: {id: 1}, order: 'id desc'}]).first
    p.keys.should == [:id, :first, :last]
  end

  it 'should find a resource by id' do
    person.class.should_receive(:find_by_id) { person }
    p = person_proxy.find(1)
    p.keys.should == [:id, :first, :last]
    p.should be_a Hash
  end

  it 'should create a resource successfuly' do
    person.class.should_receive(:create) { person }
    person.class.should_receive(:find_by_id) { person }
    p = person_proxy.create(person.attributes)
    p.should be_a Hash
  end

  it 'should create a resource unsuccessfuly' do
    person.stub(:valid?) { false }
    person.class.should_receive(:create) { person }
    person.class.should_not_receive(:find_by_id)
    p = person_proxy.create(person.attributes)
    p.should be_a Person
  end

  it 'should update a resource' do
    person.class.should_receive(:find_by_id) { person }
    person.should_receive(:update_attributes) { true }
    p = person_proxy.update(person.attributes)
    p.should be_a Person
  end

  it 'should destroy a resource' do
    person.class.should_receive(:find_by_id) { person }
    person.should_receive(:destroy) { true }
    p = person_proxy.destroy(1)
    p.should be_a Person
  end

end
