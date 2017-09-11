module Clients
  class NotesController < ApplicationController
    include ClientPathGenerator
    
    before_action :require_can_edit_clients!
    before_action :set_note, only: [:destroy]
    before_action :set_client
    
    def create
      # type = note_params[:type]
      type = "GrdaWarehouse::ClientNotes::ChronicJustification"
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
      redirect_to polymorphic_path(client_chronic_path_generator, client_id: @client.id)
    end
    
    def destroy
      begin
        @note.destroy!
        flash[:notice] = "Note was successfully deleted."
      rescue Exception => e
        flash[:error] = "Note could not be deleted."
      end
      redirect_to polymorphic_path(client_chronic_path_generator, client_id: @client.id)
    end

    def set_note
      @note = GrdaWarehouse::ClientNotes::Base.find(params[:id].to_i)
    end

    def set_client
      @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
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
