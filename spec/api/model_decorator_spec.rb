require_relative '../spec_helper'

describe Syphon::Api::ModelDecorator do
  let(:dsl) { Syphon::ResourceDSL }

  let(:resource_set) { dsl.parse(nil) { 
    resource :people do
      fields :id, :first, :last
      renames :first => :first_name, :last => :last_name
    end

    resource :users do 
      fields :email
      joins  :person, :posts
    end 

    resource :posts do 
      fields :title, :body
    end 

    resource :comments do
      fields :body
      resources :user
      collections :people
    end
  } }

  let (:person) { resource_set[:people].decorator_class.wrap(SyphonTest::PERSON) }
  let (:user) { resource_set[:users].decorator_class.wrap(SyphonTest::USER) }
  let (:post) { resource_set[:posts].decorator_class.wrap(SyphonTest::POST) }
  let (:comment) { resource_set[:comments].decorator_class.wrap(SyphonTest::COMMENT) }

  before :each do
    resource_set.each do |n,r|
      Syphon::Api::ModelDecorator.new_class(r)
    end
  end

  it 'should only return the whitelisted fields' do
    post.size.should == 2
    post.keys.should == [:title, :body]
  end


  it 'should rename aliased fields' do
    person.size.should == 3
    person.keys.should == [:id, :first_name, :last_name]
  end

  it 'should stringify large values' do
    person[:id].should be_a String
    person[:id].should == '123456789012345'
  end

  it 'should merge nested resources' do
    user.size.should == 3
    user.keys.should == [:email, :person, :posts]
  end

  it 'should wrap nested resources' do
    user[:person].size.should == 3
    user[:posts].should be_a Array
    user[:posts].first.size.should == 2
  end

  it 'should link resources and collections' do
    comment.size.should == 3
    comment[:user].should == '/users/20'
    comment[:people].should == '/people?where%5Bcomment_id%5D=100'
  end

end
