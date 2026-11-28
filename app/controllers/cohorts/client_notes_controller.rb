###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Cohorts
  class ClientNotesController < ApplicationControllerV2
    include AjaxModalRails::Controller
    include CohortAuthorization
    before_action :load_cohort
    authorize_with { cohort_policy.can_view? }
    authorize_with(only: [:new, :create, :destroy]) { cohort_policy.can_update_data? && notes_column_editable? }
    before_action :set_cohort_client
    before_action :set_note, only: [:destroy]

    def index
      @modal_size = :lg
      @column_editable = notes_column_editable?
    end

    def new
      @modal_size = :lg
      @note = note_source.new(client_id: @cohort_client.client_id)
    end

    def create
      @note = note_source.create(
        note_params.merge(
          client_id: @cohort_client.client_id,
          user_id: current_user.id,
        ),
      )
      @cohort_client.touch
      # send notifications
      if note_params[:send_notification].present? && note_params[:recipients].present?
        token = Token.tokenize(cohort_cohort_client_client_notes_path(@cohort, @cohort_client))
        note_params[:recipients].reject(&:blank?).map(&:to_i).each do |id|
          user = User.find(id)
          TokenMailer.note_added(user, token).deliver_later if user.present?
        end
      end
      respond_with(@note, location: cohort_path(id: params[:cohort_id].to_i))
    rescue StandardError
      @note = { error: 'Failed to create a note.' }
    end

    def destroy
      if @note.destroyable_by current_user
        @note.destroy
        respond_with(@note, location: cohort_path(id: params[:cohort_id].to_i))
      else
        flash[:error] = 'Unable to destroy note'
        @note = { error: 'Unable to destroy note.' }
        respond_with(@cohort, location: cohort_path(@cohort))
      end
    end

    def set_cohort_client
      @cohort_client = find_visible_cohort_client(params[:cohort_client_id])
    end

    def note_params
      params.require(:grda_warehouse_client_notes_cohort_note).permit(
        :note,
        :alert_active,
        :send_notification,
        recipients: [],
      )
    end

    def note_source
      GrdaWarehouse::ClientNotes::CohortNote
    end

    private def notes_column_editable?
      notes_column = @cohort.column_state.find { |c| c.is_a?(::CohortColumns::ClientNotes) }
      return false unless notes_column

      notes_column.display_as_editable?(current_user, nil, on_cohort: @cohort) == true
    end

    def set_note
      @note = @cohort_client.client.cohort_notes.find(params[:id].to_i)
    end

    def cohort_id
      params[:cohort_id].to_i
    end

    def flash_interpolation_options
      { resource_name: "Note for #{@note.client.pii_provider(user: current_user).full_name}" }
    end
  end
end
