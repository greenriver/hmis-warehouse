###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class NotesController < ApplicationController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_edit_window_client_notes_or_own_window_client_notes!, only: [:index, :create, :destroy]
    before_action :set_note, only: [:destroy]
    before_action :set_client
    after_action :log_client

    def index
      if can_edit_client_notes?
        @notes = @client.notes
        @note = GrdaWarehouse::ClientNotes::Base.new
      else
        @notes = @client.notes.visible_by(current_user, @client)
        @note = GrdaWarehouse::ClientNotes::WindowNote.new
      end
    end

    def alerts
      @notes = @client.alert_notes
    end

    def create
      type = note_type
      @note = GrdaWarehouse::ClientNotes::Base.new(note_params)
      begin
        raise 'Note type not found' unless GrdaWarehouse::ClientNotes::Base.available_types(current_user).map(&:to_s).include?(type)

        @client.notes.create!(
          note_params.merge(
            client_id: @client.id,
            user_id: current_user.id,
            type: type,
          ),
        )
        notice = 'Added new note'
        # send notifications
        if note_params[:send_notification].present? && note_params[:recipients].present?
          sent = []
          token = Token.tokenize(client_notes_path(client_id: @client.id))
          note_params[:recipients].reject(&:blank?).map(&:to_i).each do |id|
            user = User.find(id)
            if user.present?
              TokenMailer.note_added(user, token).deliver_later
              sent << user.name
            end
          end
          notice += '; sent to: ' + sent.join(', ') + '.' if sent.any?
        end
        flash[:notice] = notice
      rescue Exception => e
        @note.validate
        flash[:error] = "Failed to add note: #{e}"
      end
      redirect_to polymorphic_path(client_notes_path_generator, client_id: @client.id)
    end

    def destroy
      if @note.destroyable_by(current_user)
        begin
          @note.destroy!
          flash[:notice] = 'Note was successfully deleted.'
        rescue Exception
          flash[:error] = 'Note could not be deleted.'
        end
      else
        flash[:error] = 'You do not have permission to delete this note.'
      end
      redirect_to polymorphic_path(client_notes_path_generator, client_id: @client.id)
    end

    private def note_type
      return note_params[:type] if can_edit_client_notes?

      GrdaWarehouse::ClientNotes::Base.available_types(current_user).map(&:name).detect { |m| m == note_params[:type] }
    end

    private def note_scope
      if can_edit_client_notes?
        GrdaWarehouse::ClientNotes::Base
      else
        GrdaWarehouse::ClientNotes::Base.window_varieties
      end
    end

    private def set_note
      @note = note_scope.find(params[:id].to_i)
    end

    private def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    # Only allow a trusted parameter "white list" through.
    private def note_params
      params.require(:note).
        permit(
          :note,
          :type,
          :send_notification,
          recipients: [],
        )
    end

    private def title_for_show
      "#{@client.name} - Notes"
    end
  end
end
