require_relative '../spec_helper'

describe Syphon::Api::CRUDController do
  let(:dsl) { Syphon::ResourceDSL }

  let(:resource_set) { dsl.parse(nil) { 
    resource :people do
      fields :id, :first, :last
    end
  } }

  let (:model_proxy) { double }
  let (:controller)  do 
    ctrl = Class.new(ActionController::Base) 
    ctrl.send(:include, Syphon::Api::CRUDController)
    ctrl.model_proxy = model_proxy
    ctrl.new
  end
  let (:params) { { id: 1, conditions: {limit: 10}, attributes: {name: "syphon"} } }

  before :each do
    controller.stub(:respond_with)
    controller.stub(:params) { params }
  end

  it 'should delegate the index call to the model proxy' do
    model_proxy.should_receive(:all).with(params[:conditions])
    controller.index
  end

  it 'should delegate the show call to the model proxy' do
    model_proxy.should_receive(:find).with(params[:id])
    controller.show
  end

  it 'should delegate the create call to the model proxy' do
    model_proxy.should_receive(:create).with(params[:attributes])
    controller.create
  end

  it 'should delegate the update call to the model proxy' do
    model_proxy.should_receive(:update).with(params[:id], params[:attributes])
    controller.update
  end

  it 'should delegate the destroy call to the model proxy' do
    model_proxy.should_receive(:destroy).with(params[:id])
    controller.destroy
  end

end
