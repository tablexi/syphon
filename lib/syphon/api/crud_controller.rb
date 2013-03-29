module Syphon::Api::CRUDController
  extend ActiveSupport::Concern

  included do
    class_attribute :model_proxy  
    rescue_from Exception do |exception|
      render :json => { exception: exception.class.name,
                        message: exception.message, 
                        backtrace: exception.backtrace[0..10] }, 
             :status => 500
    end
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
    respond_with model_proxy.update(params[:id], params[:attributes])
  end

  def destroy
    respond_with model_proxy.destroy(params[:id])
  end

end
