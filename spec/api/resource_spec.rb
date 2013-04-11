require_relative '../spec_helper'

class ::Name; end
class ::NamesController; end
class ::ApiController; end

describe Syphon::Api::Resource do
  let(:dsl) { Syphon::ResourceDSL }
  let(:resource) { dsl.parse(nil) { resource :names do end }[:names] }

  it 'should expose a command set for the dsl' do
    (Syphon::Api::Resource.commands.keys - 
     Syphon::Resource.commands.keys).should_not be_empty
  end

  describe 'resource classes and namespacing' do

    let(:ns_resource) { dsl.parse(nil) { namespace 'api/v1' do resource :names do end end }[:names] }
    let(:sc_resource) { dsl.parse(nil) { super_controller :api; resource :names do end }[:names] }

    it 'should return the namespaced module for a resource' do
      resource.namespace_module.should == Object
      ns_resource.namespace_module.should == Api::V1
    end

    it 'should return the resource classes' do
      sc_resource.controller_class.should == NamesController
      sc_resource.super_controller_class.should == ApiController
      sc_resource.model_class.should == Name
    end

  end

end
