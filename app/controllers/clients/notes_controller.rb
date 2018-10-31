module Clients
  class NotesController < Window::Clients::NotesController
    include ClientPathGenerator
    before_action :require_can_edit_client_notes!
    after_action :log_client

    def index
      @notes = @client.notes
      @note = GrdaWarehouse::ClientNotes::Base.new
    end

    def destroy
      begin
        @note.destroy!
        flash[:notice] = "Note was successfully deleted."
      rescue Exception => e
        flash[:error] = "Note could not be deleted."
      end
      redirect_to polymorphic_path(client_notes_path_generator, client_id: @client.id)
    end
        

    def note_type
      note_params[:type]
    end

    def note_scope
      GrdaWarehouse::ClientNotes::Base
    end

    def client_scope
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
