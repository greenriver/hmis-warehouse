module Window::Clients
  class NotesController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_can_edit_window_client_notes!
    # before_action :require_can_edit_client_notes!, only: [:destroy]
    before_action :set_note, only: [:destroy]
    before_action :set_client
    
    def index
      @notes = @client.window_notes
      @note = GrdaWarehouse::ClientNotes::WindowNote.new
    end

    def create
      type = note_type
      @note = GrdaWarehouse::ClientNotes::Base.new(note_params)
      begin
        raise "Note type not found" unless GrdaWarehouse::ClientNotes::Base.available_types.map(&:to_s).include?(type)
        @client.notes.create!(note_params.merge(
          {
            client_id: @client.id, 
            user_id: current_user.id, 
            type: type
          }
        ))
        flash[:notice] = "Added new note" 
      rescue Exception => e
        @note.validate
        flash[:error] = "Failed to add note: #{e}"
      end
      redirect_to polymorphic_path(client_notes_path_generator, client_id: @client.id)
    end

    def destroy
      @note = note_scope.find_by(id: params[:id].to_i, user_id: current_user.id)
      begin
        @note.destroy!
        flash[:notice] = "Note was successfully deleted."
      rescue Exception => e
        flash[:error] = "Note could not be deleted."
      end
      redirect_to polymorphic_path(client_notes_path_generator, client_id: @client.id)
    end
    
    def set_note
      @note = note_scope.find(params[:id].to_i)
    end

    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end

    def note_type
      "GrdaWarehouse::ClientNotes::WindowNote"
    end

    def note_scope
      GrdaWarehouse::ClientNotes::WindowNote
    end

    def client_scope
      GrdaWarehouse::Hud::Client.destination.joins(source_clients: :data_source).
      where(data_sources: {visible_in_window: true})
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
end
