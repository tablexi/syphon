require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

module Syphon::Api::CRUDController
  extend ActiveSupport::Concern

  included do
    respond_to :json
    class_attribute :model_proxy, :model_scope, :instance_writer => false

    rescue_from Exception do |exception|
      render :json => { exception: exception.class.name,
                        message: exception.message, 
                        backtrace: exception.backtrace[0..10] }, 
             :status => 500
    end
  end

  module ClassMethods
    def init(resource)
      self.model_proxy = Syphon::Api::ModelProxy.new_class(resource)
      self.model_scope = resource.scope
      self
    end
  end

  def index
    respond scoped_proxy.all(params[:conditions])
  end

  def show
    respond scoped_proxy.find(params[:id])
  end

  def create
    respond scoped_proxy.create(params[:attributes])
  end

  def update
    respond scoped_proxy.update(params[:id], params[:attributes])
  end

  def destroy
    respond scoped_proxy.destroy(params[:id])
  end

private

  def respond(res)
    respond_with res, location: ''
  end

  def decorate(obj)
    scoped_proxy.wrap(obj)
  end

  def scoped_proxy
    @proxy ||= model_scope ?
      model_proxy.new(instance_exec(model_proxy.model, &model_scope)) :
      model_proxy.new
  end

end
