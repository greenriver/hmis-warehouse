###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class NotesController < ApplicationController
    include PjaxModalController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_edit_window_client_notes_or_own_window_client_notes!
    before_action :set_note, only: [:destroy]
    before_action :set_client
    after_action :log_client

    def index
      if can_edit_client_notes?
        @notes = @client.notes
        @note = GrdaWarehouse::ClientNotes::Base.new
      else
        @notes = @client.window_notes.visible_by(current_user, @client)
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
        raise 'Note type not found' unless GrdaWarehouse::ClientNotes::Base.available_types.map(&:to_s).include?(type)

        @client.notes.create!(note_params.merge(
                                client_id: @client.id,
                                user_id: current_user.id,
                                type: type,
                              ))
        notice = 'Added new note'
        # send notifications
        if note_params[:send_notification].present? && note_params[:recipients].present?
          sent = []
          token = Token.tokenize(window_client_notes_path(client_id: @client.id))
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
      @note = note_scope.find_by(id: params[:id].to_i, user_id: current_user.id) unless can_edit_client_notes?
      begin
        @note.destroy!
        flash[:notice] = 'Note was successfully deleted.'
      rescue Exception
        flash[:error] = 'Note could not be deleted.'
      end
      redirect_to polymorphic_path(client_notes_path_generator, client_id: @client.id)
    end

    private def note_type
      if can_edit_client_notes?
        note_params[:type]
      else
        'GrdaWarehouse::ClientNotes::WindowNote'
      end
    end

    private def note_scope
      if can_edit_client_notes?
        GrdaWarehouse::ClientNotes::Base
      else
        GrdaWarehouse::ClientNotes::WindowNote
      end
    end

    private def set_note
      @note = note_scope.find(params[:id].to_i)
    end

    private def set_client
      @client = searchable_client_scope.find(params[:client_id].to_i)
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
