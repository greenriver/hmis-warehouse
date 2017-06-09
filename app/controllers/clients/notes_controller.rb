module Clients
  class NotesController < ApplicationController
    before_action :require_can_edit_clients!
    
    def destroy
      note = GrdaWarehouse::ClientNotes::Base.find(params[:id].to_i)
      client = note.client
      begin
        note.destroy!
        flash[:notice] = "Note was successfully deleted."
      rescue Exception => e
        flash[:error] = "Note could not be deleted."
      end
      redirect_to client_path(client)
    end
  end
end
