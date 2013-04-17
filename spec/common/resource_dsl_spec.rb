require_relative '../spec_helper'

describe Syphon::ResourceDSL do
  let(:dsl) { Syphon::ResourceDSL }

  describe 'dsl parser' do

    it 'should parse a resource description' do
      set = dsl.parse nil do
        resource :user do end
      end

      set.size.should == 1
      set[:user].should be_a Syphon::Resource
      set[:user].name.should == :user
    end

    it 'should parse a resource description with limited actions' do
      set1 = dsl.parse nil do
        resource :user,  only: [:index, :show] do
        end
      end

      set2 = dsl.parse nil do
        resource :user,  except: [:update, :create, :destroy] do
        end
      end

      set3 = dsl.parse nil do
        resource :user,  only: [:index, :show], except: [:show] do
        end
      end

      set1[:user].only.should == [:index, :show]
      set2[:user].only.should == [:index, :show]
      set3[:user].only.should == [:index]
    end

    it 'should parse a hidden description' do
      set = dsl.parse nil do
        resource :user, hidden: true do end
      end

      set[:user].hidden.should be_true
    end

    it 'should parse all inner resource properties' do
      values = {
        scope:       Proc.new { |m| m.where(id: current_user.id) },
        primary_key: :token,
        model:       :MyUser,
        controller:  :my_users,
        routes: { :show  => '/users/:token',
                  :index => '/users'},
        fields:       [ :first, :last, :email ],
        renames:      { :first => :first_name, :last => :last_name },
        joins:        [ :account ],
        resources:    [ :person ],
        collections:  [ :posts ]
      }

      set = dsl.parse nil do
        resource :user do 
          scope       &values[:scope]
          primary_key values[:primary_key]
          model       values[:model]
          controller  values[:controller]
          routes      values[:routes]
          fields      *values[:fields]
          renames     values[:renames]
          joins       *values[:joins]
          resources   *values[:resources]
          collections *values[:collections]
        end
      end

      res = set[:user]
      values.each do |k,v|
        res.send(k).should == v
      end
    end

    it 'should parse a namespaced resource description' do
      set = dsl.parse nil do
        namespace :api do
          namespace :v1 do
            resource :user do end
          end
        end
      end

      set[:user].namespace.should == 'api/v1'
    end

    it 'should parse a super controller for multiple resources' do
      set = dsl.parse nil do
        namespace :v1 do
          super_controller :api_v1
          namespace :admin do
            resource :subscriptions do end
          end
          resource :users do end
          resource :accounts do end
        end
      end

      set[:users].super_controller.should == '/v1/api_v1'
      set[:accounts].super_controller.should == '/v1/api_v1'
      set[:subscriptions].super_controller.should == '/v1/api_v1'
    end

    it 'should raise for illegal context nesting' do
      expect { dsl.parse(nil) { resource(:user) { super_controller :api_v1 } } }.to raise_error 
      expect { dsl.parse(nil) { resource(:user) { namespace :v1 } } }.to raise_error 
      expect { dsl.parse(nil) { resource(:user) { resource :account } } }.to raise_error 
      expect { dsl.parse(nil) { namespace(:user) { model :account } } }.to raise_error 
    end

  end

  describe 'config parser' do

    it 'should convert a configuration file into a resource set' do
      config = Support.json('api_spec')
      set = dsl.parse(config)
      config.each do |res|
        res.each do |k,v|
          set[res['name']].send(k).should == v
        end
      end
    end

  end
end
