class HmisExportsController < ApplicationController
  before_action :require_can_export_hmis_data!
  before_action :set_export, only: [:show, :edit, :update, :destroy]

  def index
   
  end

  def new

  end

  def create
    
  end

  def destroy
    
  end

end
