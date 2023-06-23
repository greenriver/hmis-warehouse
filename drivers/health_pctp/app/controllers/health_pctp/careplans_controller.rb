###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class CareplansController < IndividualPatientController
    include AjaxModalRails::Controller
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan, only: [:edit, :update, :show, :destroy, :download, :remove_file]
    before_action :set_upload_object, only: [:edit, :update, :download, :remove_file]

    def new
      @careplan = if @patient.pctps.in_progress.exists?
        @patient.pctps.in_progress.first
      else
        pctp = @patient.pctps.create!(user: current_user)
        @patient.pctp_careplans.create(instrument: pctp)
        pctp.populate_from_ca(current_user)
        pctp
      end
      redirect_to edit_client_health_pctp_careplan_path(@client, @careplan)
    end

    def edit
    end

    def update
      old_ccm_status = @careplan.review_by_ccm_complete
      old_rn_status = @careplan.review_by_rn_complete
      old_delivered_status = @careplan.was_sent_to_pcp
      @careplan.assign_attributes(careplan_params)

      set_upload_object
      @careplan.health_file.set_calculated!(current_user.id, @client.id) if @careplan.health_file.present?

      boolean_toggled(old_ccm_status, @careplan.review_by_ccm_complete, :reviewed_by_ccm_on, :reviewed_by_ccm_id)
      boolean_toggled(old_rn_status, @careplan.review_by_rn_complete, :reviewed_by_rn_on, :reviewed_by_rn_id)
      boolean_toggled(old_delivered_status, @careplan.was_sent_to_pcp, :sent_to_pcp_on, :sent_to_pcp_by_id)

      @careplan.save

      @patient.current_qa_factory.complete_careplan(@careplan) if @careplan.completed?
      @patient.current_qa_factory.review_careplan(@careplan) if @careplan.reviewed?
      @patient.current_qa_factory.approve_careplan(@careplan) if @careplan.approved?
      respond_with @careplan, location: client_health_careplans_path(@client)
    end

    def show
    end

    def destroy
      @patient.pctp_careplans.find_by(instrument: @careplan)&.destroy
      @careplan.destroy
      respond_with @careplan, location: client_health_careplans_path(@client)
    end

    private def boolean_toggled(old_value, new_value, date_attr, who_attr)
      return unless new_value.present?

      if new_value == '0' # when not checked, clear who and when
        @careplan.assign_attributes(date_attr => nil, who_attr => nil)
      elsif new_value == '1' && ! old_value # if checked, and changed, set who and when
        @careplan.assign_attributes(date_attr => Date.current, who_attr => current_user.id)
      end
    end

    GROUP_PARAMS = [
      :race,
      :accommodation_types,
      :accessibility_equipment,
    ].freeze

    private def careplan_params
      permitted_cols = ::HealthPctp::Careplan.column_names.map(&:to_sym) -
        GROUP_PARAMS -
        [:id, :user_id, :patient_id, :created_at, :updated_at] + # Deny protected columns, be careful adding new columns!
        [:review_by_ccm_complete, :review_by_rn_complete, :was_sent_to_pcp]

      permitted_cols -= [:reviewed_by_ccm_id, :reviewed_by_ccm_on] unless current_user.can_approve_cha?
      permitted_cols -= [:reviewed_by_rn_id, :reviewed_by_rn_on] unless current_user.can_approve_careplan?

      permitted_group_cols = GROUP_PARAMS.map { |key| [key, []] }.to_h
      params.require(:health_pctp_careplan).permit(
        permitted_cols,
        **permitted_group_cols,
        health_file_attributes: [
          :id,
          :file,
          :file_cache,
        ],
      )
    end

    private def set_careplan
      @careplan = @patient.pctps.find(params[:id])
    end

    def set_upload_object
      # edit_client_health_pctp_careplan_path
      @upload_object = @careplan
      @location = edit_client_health_pctp_careplan_path(client_id: @client.id, id: @careplan.id)
      @download_path = @upload_object.downloadable? ? download_client_health_pctp_careplan_path(client_id: @client.id, id: @careplan.id) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : { confirm: 'Form errors must be fixed before you can download this file.' }
      @remove_path = @upload_object.downloadable? ? remove_file_client_health_pctp_careplan_path(client_id: @client.id, id: @careplan.id) : '#'
    end

    private def careplan_source
      HealthPctp::Careplan
    end
  end
end
