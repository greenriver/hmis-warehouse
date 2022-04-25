###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class FollowUpsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ArelHelper
    include ClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_vpr
    before_action :set_follow_up, only: [:edit, :update, :destroy]

    def new
      @pdf = false
      @html = true
      @follow_up = follow_up_source.new(user: current_user, patient: @patient)
      @follow_up.set_defaults
    end

    def edit
      @pdf = false
      @html = true
    end

    def show
      respond_to do |format|
        format.html do
          @pdf = false
          @html = true
        end
        format.pdf do
          @pdf = true
          @html = false
          render_pdf!
        end
      end
    end

    private def render_pdf!
      file_name = "VPR Follow Up #{DateTime.current.to_s(:db)}"
      send_data pdf, filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    def pdf
      grover_options = {
        display_url: root_url,
        displayHeaderFooter: true,
        headerTemplate: '<h2>Header</h2>',
        footerTemplate: '<h6 class="text-center">Footer</h6>',
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        margin: {
          top: '.5in',
          bottom: '.5in',
          left: '.4in',
          right: '.4in',
        },
        debug: {
          # headless: false,
          # devtools: true
        },
      }
      grover_options[:executablePath] = ENV['CHROMIUM_PATH'] if ENV['CHROMIUM_PATH']
      html = render_to_string('health_flexible_service/follow_up/show')
      Grover.new(html, grover_options).to_pdf
    end

    def create
      options = permitted_params.merge(user: current_user, patient: @patient, vpr: @vpr)
      @follow_up = follow_up_source.create(options)
      @vpr.update(end_date: vpr_end_date + 6.months, open: most_recent_follow_up.additional_flex_services_requested?)
      respond_with(@follow_up, location: client_health_flexible_service_vprs_path(@client))
    end

    def update
      options = permitted_params.merge(user: current_user)
      @follow_up.update(options)
      @vpr.update(end_date: vpr_end_date + 6.months, open: most_recent_follow_up.additional_flex_services_requested?)
      respond_with(@follow_up, location: client_health_flexible_service_vprs_path(@client))
    end

    def destroy
      @follow_up.destroy
      @vpr.update(end_date: vpr_end_date + 6.months, open: most_recent_follow_up.additional_flex_services_requested?)
      respond_with(@follow_up, location: client_health_flexible_service_vprs_path(@client))
    end

    private def most_recent_follow_up
      @vpr.follow_ups.order(completed_on: :desc).first
    end

    private def vpr_end_date
      [
        @vpr.follow_ups.extension_requested.maximum(:completed_on),
        @vpr.planned_on,
      ].compact.max
    end

    private def follow_up_source
      HealthFlexibleService::FollowUp
    end

    private def vpr_source
      HealthFlexibleService::Vpr
    end

    private def follow_up_scope
      follow_up_source.order(created_at: :desc)
    end

    private def set_vpr
      @vpr = vpr_source.find(params[:vpr_id].to_i)
    end

    private def set_follow_up
      @follow_up = follow_up_source.find(params[:id].to_i)
    end

    private def permitted_params
      params.require(:follow_up).permit(
        [
          :completed_on,
          :first_name,
          :middle_name,
          :last_name,
          :dob,
          :delivery_first_name,
          :delivery_last_name,
          :delivery_organization,
          :delivery_phone,
          :delivery_email,
          :reviewer_first_name,
          :reviewer_last_name,
          :reviewer_organization,
          :reviewer_phone,
          :reviewer_email,
          :services_completed,
          :goal_status,
          :additional_flex_services_requested,
          :additional_flex_services_requested_detail,
          :agreement_to_flex_services,
          :agreement_to_flex_services_detail,
          :aco_approved_flex_services,
          :aco_approved_flex_services_detail,
          :aco_approved_flex_services_on,
        ],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Flexible Service VPR Follow Up Form' }
    end
  end
end
