###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EngagementCalculator
    include Rails.application.routes.url_helpers

    def initialize(patient)
      @patient = patient
      @client = patient.client
      @valid_after = patient.contributing_enrollment_start_date - 1.year
    end

    # TODO 10/4/22 Participation form is no longer used, left here for now
    def participation_form_status
      signed_participation_form = @patient.participation_forms.recent.first
      return [:no_signed_form, 'Participation Form', new_client_health_participation_form_path(@client), true, nil] if signed_participation_form.blank?
      return [:too_old, 'Participation Form', new_client_health_participation_form_path(@client), true, "Last signed on #{signed_participation_form.signature_on}"] if signed_participation_form.signature_on < @valid_after

      [:valid, 'Participation Form', edit_client_health_participation_form_path(@client, signed_participation_form), true, nil]
    end

    def release_form_status
      signed_release_form = @patient.release_forms.recent.first
      return [:no_signed_form, 'Participation and Release of Information', new_client_health_release_form_path(@client), true, nil] if signed_release_form.blank?
      return [:too_old, 'Participation and Release of Information', new_client_health_release_form_path(@client), true, "Last signed on #{signed_release_form.signature_on}"] if signed_release_form.signature_on < @valid_after
      return [:expired, 'Participation and Release of Information', new_client_health_release_form_path(@client), true, "Expired on #{signed_release_form.signature_on + 2.years}"] if signed_release_form.signature_on + 2.years <= Date.current
      return [:in_progress, 'Participation and Release of Information', edit_client_health_release_form_path(@client, signed_release_form), true, 'Incomplete, file upload is missing'] if signed_release_form.health_file.blank? && signed_release_form.file_location.blank?

      [:valid, 'Participation and Release of Information', edit_client_health_release_form_path(@client, signed_release_form), true, nil]
    end

    def ssm_status
      ssm_form = @patient.hrsn_screenings.recent.first&.instrument
      return [:no_signed_form, 'HRSN Screening', new_client_health_thrive_assessment_assessment_path(@client), false, nil] if ssm_form.blank?

      if ssm_form.completed?
        return [:too_old, 'HRSN Screening', new_client_health_thrive_assessment_assessment_path(@client), false, "Last completed on #{ssm_form.completed_at.to_date}"] if ssm_form.completed_at < @valid_after
        return [:expired, 'HRSN Screening', new_client_health_thrive_assessment_assessment_path(@client), false, "Last completed on #{ssm_form.completed_at.to_date}"] unless ssm_form.active?

        [:valid, 'HRSN Screening', ssm_form.edit_path, true, nil]
      else
        return [:too_old, 'HRSN Screening', new_client_health_thrive_assessment_assessment_path(@client), false, "Last completed on #{ssm_form.completed_at.to_date}"] if ssm_form.completed_at.present? && ssm_form.completed_at < @valid_after

        prior_forms = @patient.hrsn_screenings.count > 1
        return [:being_updated, 'HRSN Screening', ssm_form.edit_path, true, "Started on #{ssm_form.created_at.to_date}"] if prior_forms

        [:in_progress, 'HRSN Screening', ssm_form.edit_path, true, "Started on #{ssm_form.created_at.to_date}"]
      end
    end

    def cha_status
      cha_form = @patient.comprehensive_health_assessments.recent.first
      return [:no_signed_form, 'Comprehensive Health Assessment', new_client_health_cha_path(@client), false, nil] if cha_form.blank?
      return [:too_old, 'Comprehensive Health Assessment', new_client_health_cha_path(@client), false, "Last completed on #{cha_form.completed_at.to_date}"] if cha_form.completed_at.present? && cha_form.completed_at < @valid_after

      if cha_form.completed?
        return [:expired, 'Comprehensive Health Assessment', new_client_health_cha_path(@client), false, "Last completed on #{cha_form.completed_at.to_date}"] unless cha_form.active?

        [:valid, 'Comprehensive Health Assessment', client_health_cha_path(@client, cha_form), true, nil]
      else
        prior_forms = @patient.comprehensive_health_assessments.count > 1
        return [:being_updated, 'Comprehensive Health Assessment', client_health_cha_path(@client, cha_form), true, "Started on #{cha_form.created_at.to_date}"] if prior_forms

        [:in_progress, 'Comprehensive Health Assessment', client_health_cha_path(@client, cha_form), true, "Started on #{cha_form.created_at.to_date}"]
      end
    end

    def careplan_status
      careplan = @patient.careplans.sorted.first
      return [:no_signed_form, 'PCTP Approved', new_client_health_careplan_path(@client), false, nil] if careplan.blank?
      return [:valid, 'PCTP Approved', client_health_careplan_path(@client, careplan), false, nil] if careplan.active?

      if careplan.editable?
        return [:being_updated, 'PCTP Approved', client_health_careplan_path(@client, careplan), false, "Started on #{careplan.created_at.to_date}"] if @patient.careplans.expired.exists?

        [:in_progress, 'PCTP Approved', client_health_careplan_path(@client, careplan), false, "Started on #{careplan.created_at.to_date}"]
      elsif careplan.signed?
        [:in_progress, 'PCTP Approved', client_health_careplan_path(@client, careplan), false, "Patient signed on #{careplan.patient_signed_on.to_date}"]
      elsif careplan.completed?
        [:expired, 'PCTP Approved', new_client_health_careplan_path(@client), false, "Last completed on #{careplan.completed_on}"]
      else
        [:expired, 'PCTP Approved', new_client_health_careplan_path(@client), false, "Incomplete, last updated on #{careplan.updated_at.to_date}"]
      end
    end
  end
end
