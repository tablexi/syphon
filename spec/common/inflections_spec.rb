require_relative '../spec_helper'

module ::TestConst; end

describe Syphon::Inflections do
  let(:inflector) { class Inflector; end.extend Syphon::Inflections }

  it 'should safely constantize a constant name' do
    inflector.constantize('NS1::TestConst').should be_nil
  end

  it 'should classify a string or symbol' do
    inflector.classify(:users).should == 'User'
    inflector.classify('accounts').should == 'Account'
  end

  it 'should controllerize a string or symbol' do
    inflector.controllerize(:users).should == 'UsersController'
    inflector.controllerize('accounts').should == 'AccountsController'
  end

  it 'should singularize a constant string or symbol' do
    inflector.singularize(:users).should == 'user'
    inflector.singularize('accounts').should == 'account'
  end

  it 'should pluralize a constant string or symbol' do
    inflector.pluralize(:user).should == 'users'
    inflector.pluralize('account').should == 'accounts'
  end

end
