require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

module Syphon::Api::CRUDController
  extend ActiveSupport::Concern

  included do
    respond_to :json
    class_attribute :model_proxy, :instance_writer => false

    rescue_from Exception do |exception|
      render :json => { exception: exception.class.name,
                        message: exception.message, 
                        backtrace: exception.backtrace[0..10] }, 
             :status => 500
    end
  end

  module ClassMethods
    def init(resource)
      self.model_proxy = Class.new(Syphon::Api::ModelProxy).init(resource)
      self
    end
  end

  def index
    respond model_proxy.all(params[:conditions])
  end

  def create
    respond model_proxy.create(params[:attributes])
  end

  def show
    respond model_proxy.find(params[:id])
  end

  def update
    respond model_proxy.update(params[:id], params[:attributes])
  end

  def destroy
    respond model_proxy.destroy(params[:id])
  end

private

  def respond(res)
    respond_with res, location: ''
  end

end
