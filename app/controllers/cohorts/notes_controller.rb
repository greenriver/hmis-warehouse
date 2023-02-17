###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cohorts
  class NotesController < ApplicationController
    include AjaxModalRails::Controller
    include CohortAuthorization
    before_action :require_can_access_cohort!
    before_action :require_can_update_some_cohort_data!, only: [:new, :create, :destroy]
    before_action :set_note, only: [:destroy]
    before_action :set_cohort_client

    def index
      @modal_size = :lg
      notes_column = @cohort.column_state.find { |c| c.is_a?(::CohortColumns::Notes) }
      @column_editable = notes_column.display_as_editable?(current_user, nil, on_cohort: @cohort)
    end

    def new
      @modal_size = :lg
      @note = note_source.new(cohort_client_id: @cohort_client.id)
    end

    def create
      @note = note_source.create(
        note_params.merge(
          cohort_client_id: @cohort_client.id,
          user_id: current_user.id,
        ),
      )
      @note.cohort_client.touch
      # send notifications
      if note_params[:send_notification].present? && note_params[:recipients].present?
        token = Token.tokenize(cohort_cohort_client_cohort_client_notes_path(@cohort, @cohort_client))
        note_params[:recipients].reject(&:blank?).map(&:to_i).each do |id|
          user = User.find(id)
          TokenMailer.note_added(user, token).deliver_later if user.present?
        end
      end
      respond_with(@note, location: cohort_path(@cohort))
    rescue StandardError
      @note = { error: 'Failed to create a note.' }
    end

    def destroy
      path = if request.xhr?
        cohort_path(@cohort)
      else
        cohort_cohort_client_client_notes_path(@cohort, @cohort_client)
      end

      if @note.destroyable_by current_user
        @note.destroy
        respond_with(@note, location: path)
      else
        flash[:error] = 'Unable to destroy note'
        @note = { error: 'Unable to destroy note.' }
        respond_with(@cohort, location: path)
      end
    end

    def note_params
      params.require(:grda_warehouse_cohort_client_note).permit(
        :note,
        :send_notification,
        recipients: [],
      )
    end

    def note_source
      GrdaWarehouse::CohortClientNote
    end

    def set_note
      @note = note_source.find(params[:id].to_i)
    end

    def set_cohort_client
      @cohort = GrdaWarehouse::Cohort.find(params[:cohort_id].to_i)
      @cohort_client = @cohort.cohort_clients.find(params[:cohort_client_id].to_i)
    end

    def cohort_id
      params[:cohort_id].to_i
    end

    def flash_interpolation_options
      { resource_name: "Note for #{@note.client.name}" }
    end
  end
end
