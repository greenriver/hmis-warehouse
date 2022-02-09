###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class VprsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ArelHelper
    include ClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_vpr, only: [:show, :edit, :update, :destroy]

    def index
      @vprs = @patient.flexible_services
      @follow_ups = @patient # .flexible_service_follow_ups
    end

    def new
      @pdf = false
      @html = true
      @vpr = vpr_source.new(user: current_user, patient: @patient)
      @vpr.set_defaults
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
      file_name = "VPR #{DateTime.current.to_s(:db)}"
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
      html = render_to_string('health_flexible_service/vprs/show')
      Grover.new(html, grover_options).to_pdf
    end

    def create
      options = permitted_params.merge(user: current_user, patient: @patient)
      @vpr = vpr_source.create(options)
      respond_with(@vpr, location: client_health_flexible_service_vprs_path(@client))
    end

    def update
      options = permitted_params.merge(user: current_user, patient: @patient)
      @vpr = @vpr.update(options)
      respond_with(@vpr, location: client_health_flexible_service_vprs_path(@client))
    end

    def destroy
      @vpr.destroy
      respond_with(@vpr, location: client_health_flexible_service_vprs_path(@client))
    end

    private def vpr_source
      HealthFlexibleService::Vpr
    end

    private def vpr_scope
      vpr_source.order(created_at: :desc)
    end

    private def set_vpr
      @vpr = vpr_source.find(params[:id].to_i)
    end

    private def permitted_params
      attrs = [
        :planned_on,
        :first_name,
        :middle_name,
        :last_name,
        :dob,
        :accommodations_needed,
        :contact_type,
        :phone,
        :email,
        :additional_contact_details,
        :main_contact_first_name,
        :main_contact_last_name,
        :main_contact_organization,
        :main_contact_phone,
        :main_contact_email,
        :reviewer_first_name,
        :reviewer_last_name,
        :reviewer_organization,
        :reviewer_phone,
        :reviewer_email,
        :representative_first_name,
        :representative_last_name,
        :representative_organization,
        :representative_phone,
        :representative_email,
        :member_agrees_to_plan,
        :member_agreement_notes,
        :aco_approved,
        :aco_approved_on,
        :aco_rejection_notes,
        :health_needs_screened_on,
        :complex_physical_health_need,
        :complex_physical_health_need_detail,
        :behavioral_health_need,
        :behavioral_health_need_detail,
        :activities_of_daily_living,
        :activities_of_daily_living_detail,
        :ed_utilization,
        :ed_utilization_detail,
        :high_risk_pregnancy,
        :high_risk_pregnancy_detail,
        :risk_factors_screened_on,
        :experiencing_homelessness,
        :experiencing_homelessness_detail,
        :at_risk_of_homelessness,
        :at_risk_of_homelessness_detail,
        :at_risk_of_nutritional_deficiency,
        :at_risk_of_nutritional_deficiency_detail,
        :health_and_risk_notes,
        :receives_snap,
        :receives_wic,
        :receives_csp,
        :receives_other,
        :receives_other_detail,
        :gender,
        :gender_detail,
        :sexual_orientation,
        :sexual_orientation_detail,
        :race_detail,
        :primary_language,
        :primary_language_refused,
        :education,
        :education_detail,
        :employment_status,
        race: [],
      ]
      attrs += vpr_source.service_attributes
      params.require(:vpr).permit(attrs)
    end

    def flash_interpolation_options
      { resource_name: 'Flexible Service Verification Form' }
    end
  end
end
