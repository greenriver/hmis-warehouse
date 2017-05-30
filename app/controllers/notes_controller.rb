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
    @note = GrdaWarehouse::ClientNotes::Base.new(note_params)
  end
  
  # Only allow a trusted parameter "white list" through.
  private def note_params
    params.
      permit(
        :note,
        :type,
      )
  end
end
