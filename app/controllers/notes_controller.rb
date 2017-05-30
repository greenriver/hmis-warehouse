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
  
  def create
    @client = GrdaWarehouse::Hud::Client.find(params["client_id"])
    type = note_params[:type]
    @note = GrdaWarehouse::ClientNotes::Base.new(note_params)
    klass = type.constantize if GrdaWarehouse::ClientNotes::Base.available_types.map(&:to_s).include?(type)
    unless klass.present?
      flash[:error] = "Failed to add Note, note type not found"
      redirect_to client_path(@client)
      return
    end
    opts = note_params.merge({client_id: @client.id, user_id: 3})
    begin
      new_note = klass.create!(opts)
      flash[:notice] = "Added new note"
      redirect_to client_path(@client)
    rescue Exception => e
      @note.validate
      flash[:error] = "Failed to add Note #{e}"
      redirect_to client_path(@client)
    end
  end
  
  # Only allow a trusted parameter "white list" through.
  private def note_params
    params.require(:note).
      permit(
        :note,
        :type,
      )
  end
end
