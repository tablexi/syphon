require_relative '../spec_helper'

class ::Admin; end # need this to test correct constantization
class ::User; end
class ::UsersController; end
class ::ApiController; end

describe Syphon::Api::Resource do
  let(:dsl) { Syphon::ResourceDSL }

  it 'should expose a command set for the dsl' do
    (Syphon::Api::Resource.commands.keys - 
     Syphon::Resource.commands.keys).should_not be_empty
  end

  describe 'resource classes and namespacing' do

    let(:resource_set1) { dsl.parse(nil) { resource :users do end } }
    let(:resource_set2) { dsl.parse(nil) { namespace 'api/v1/admin' do resource :users do end end } }
    let(:resource_set3) { dsl.parse(nil) { super_controller :api; resource :users do end } }

    it 'should return the namespaced module for a resource' do
      resource_set1[:users].namespace_module.should == Object
      resource_set2[:users].namespace_module.should == Api::V1::Admin
    end

    it 'should return the resource classes' do
      resource = resource_set3[:users]
      resource.controller_class.should == UsersController
      resource.super_controller_class.should == ApiController
      resource.model_class.should == User
    end

  end

end
