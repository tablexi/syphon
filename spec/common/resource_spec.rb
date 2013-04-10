require_relative '../spec_helper'

describe Syphon::Resource do
  let(:dsl) { Syphon::ResourceDSL }
  let(:resource) { dsl.parse(nil) { resource :names do end }[:names] }

  it 'should expose a command set for the dsl' do
    Syphon::Resource.commands.should_not be_empty
  end

  it 'should be serializable to a hash for api discovery' do
    keys = [:name, :namespace, :resources, :collections, :only]
    keys.each do |k|
      resource.should respond_to k
    end
  end

  it 'should determine the singular resource name' do
    resource.resource_name.to_s.should == 'name'
  end

  it 'should determine the collection resource name' do
    resource.collection_name.to_s.should == 'names'
  end

  it 'should determine the singular resource uri' do
    resource.resource_uri(10).should == '/names/10'
  end

  it 'should determine the collection resource uri' do
    resource.collection_uri.should == '/names'
  end

  it 'should determine the query resource uri' do
    resource.query_uri(:account_id, 1).should == '/names?where%5Baccount_id%5D=1'
  end

end
