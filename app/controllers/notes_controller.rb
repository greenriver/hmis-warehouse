class NotesController < ApplicationController
  before_action :require_can_view_clients_or_window!
  
  def new
    @note = GrdaWarehouse::ClientNotes::Base.new
  end
  
  def index
  end
  
  def update
  end
  
  def show
  end
  
  def create
    # raise params.inspect
  end
end
