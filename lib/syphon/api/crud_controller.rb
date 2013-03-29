module Syphon::Api::CRUDController
  extend ActiveSupport::Concern

  included do
    class_attribute :model_proxy  
  end

  def index
    respond_with model_proxy.all(params[:conditions])
  end

  def create
    respond_with model_proxy.create(params[:attributes])
  end

  def show
    respond_with model_proxy.find(params[:id])
  end

  def update
    model_proxy.update(params[:id], params[:attributes])
  end

  def destroy
    model_proxy.destroy(params[:id])
  end

end
