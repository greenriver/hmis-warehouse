###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EngagementCalculator
    include Rails.application.routes.url_helpers

    def initialize(patient)
      @patient = patient
      @client = patient.client
    end

    # TODO 10/4/22 Participation form is no longer used, left here for now
    def participation_form_status
      signed_participation_form = @patient.participation_forms.recent.first
      return [:no_signed_form, 'Participation Form', new_client_health_participation_form_path(@client), true, nil] if signed_participation_form.blank?

      [:valid, 'Participation Form', edit_client_health_participation_form_path(@client, signed_participation_form), true, nil]
    end

    def release_form_status
      signed_release_form = @patient.release_forms.recent.first
      return [:no_signed_form, 'Participation and Release of Information', new_client_health_release_form_path(@client), true, nil] if signed_release_form.blank?
      return [:expired, 'Participation and Release of Information', new_client_health_release_form_path(@client), true, "Expired on #{signed_release_form.signature_on + 2.years}"] if signed_release_form.signature_on + 2.years <= Date.current
      return [:in_progress, 'Participation and Release of Information', edit_client_health_release_form_path(@client, signed_release_form), true, 'Incomplete, file upload is missing'] if signed_release_form.health_file.blank? && signed_release_form.file_location.blank?

      [:valid, 'Participation and Release of Information', edit_client_health_release_form_path(@client, signed_release_form), true, nil]
    end

    def ssm_status
      ssm_form = @patient.hrsn_screenings.recent.first&.instrument
      return [:no_signed_form, 'HRSN Screening', new_client_health_thrive_assessment_assessment_path(@client), false, nil] if ssm_form.blank?

      if ssm_form.completed?
        return [:expired, 'HRSN Screening', new_client_health_thrive_assessment_assessment_path(@client), false, "Last completed on #{ssm_form.completed_at.to_date}"] unless ssm_form.active?

        [:valid, 'HRSN Screening', ssm_form.edit_path, true, nil]
      else
        prior_forms = @patient.hrsn_screenings.count > 1
        return [:being_updated, 'HRSN Screening', ssm_form.edit_path, true, "Started on #{ssm_form.created_at.to_date}"] if prior_forms

        [:in_progress, 'HRSN Screening', ssm_form.edit_path, true, "Started on #{ssm_form.created_at.to_date}"]
      end
    end

    def cha_status
      cha_form = @patient.ca_assessments.recent.first&.instrument
      return [:no_signed_form, 'Comprehensive Assessment', new_client_health_comprehensive_assessment_assessment_path(@client), false, nil] if cha_form.blank?

      if cha_form.completed?
        return [:expired, 'Comprehensive Assessment', new_client_health_comprehensive_assessment_assessment_path(@client), false, "Last completed on #{cha_form.completed_at.to_date}"] unless cha_form.active?

        [:valid, 'Comprehensive Assessment', cha_form.edit_path, true, nil]
      else
        prior_forms = @patient.ca_assessments.count > 1
        return [:being_updated, 'Comprehensive Assessment', cha_form.edit_path, true, "Started on #{cha_form.created_at.to_date}"] if prior_forms

        [:in_progress, 'Comprehensive Assessment', cha_form.edit_path, true, "Started on #{cha_form.created_at.to_date}"]
      end
    end

    def careplan_status
      careplan = @patient.pctp_careplans.sorted.first&.instrument
      return [:no_signed_form, 'PCTP Approved', new_client_health_pctp_careplan_path(@client, @patient), false, nil] if careplan.blank?
      return [:valid, 'PCTP Approved', careplan.show_path, false, nil] if careplan.active?

      if careplan.editable?
        return [:in_progress, 'PCTP Approved', careplan.edit_path, false, "Patient signed on #{careplan.patient_signed_on.to_date}"] if careplan.completed?

        [:in_progress, 'PCTP Approved', careplan.edit_path, false, "Started on #{careplan.created_at.to_date}"]
      else
        return [:expired, 'PCTP Approved', new_client_health_pctp_careplan_path(@client, @patient), false, "Last completed on #{careplan.completed_on}"] if careplan.completed?

        [:expired, 'PCTP Approved', new_client_health_pctp_careplan_path(@client, @patient), false, "Incomplete, last updated on #{careplan.updated_at.to_date}"]
      end
    end
  end
end
