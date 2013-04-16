require_relative '../spec_helper'

describe Syphon::Api::RailsConfig do
  let(:dsl) { Syphon::ResourceDSL }

  let(:resource_set) { dsl.parse(nil) { 
    resource :people do
      fields :id, :first, :last
    end

    resource :posts do
      routes :index => ['/users/:user_id/posts', { :as => :posts }],
             :show =>  ['/users/:user_id/posts/post_id', { :as => :post }] 

      fields :id, :first, :last
    end

    resource :comments, :hidden => true do
      fields :id, :first, :last
    end
  } }

  let (:rconfig) { Syphon::Api::RailsConfig }
  let (:routes) { Application.routes.routes.named_routes }

  before :all do
    resource_set.each do |name, resource|
      rconfig.add_resource(Application, resource)
    end
  end

  it 'should build the necessary controllers and include the CRUD module' do
    resource_set.each do |name, resource|
      resource.controller_class.should be_a Class
      resource.controller_class.ancestors.should include Syphon::Api::CRUDController
    end
  end

  it 'should create resourceful routes by default' do
    routes.should include 'person'
    routes.should include 'people'
  end

  it 'should build custom routes when set explicitly' do
    routes.should include 'post'
    routes.should include 'posts'
  end

  it 'should not build routes when hidden' do
    routes.should_not include 'comments'
    routes.should_not include 'comment'
  end
end
