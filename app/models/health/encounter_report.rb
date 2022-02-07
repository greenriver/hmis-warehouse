###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: none
# Control: no PHI, PHI is in encounter_records

module Health
  class EncounterReport < HealthBase
    include Rails.application.routes.url_helpers

    has_many :encounter_records, dependent: :destroy

    def run_and_save!
      update(started_at: Time.current)
      activity_scope.find_in_batches do |batch|
        records = []
        batch.each do |activity|
          records << record_from(activity)
        end
        Health::EncounterRecord.import(records.compact)
      end

      activity_scope_with_preload.find_in_batches do |batch|
        records = []
        batch.each do |activity|
          records << record_from(activity)
        end
        Health::EncounterRecord.import(records.compact)
      end
      update(completed_at: Time.current)
    end

    private def record_from(activity)
      patient = activity.patient
      return nil unless patient

      record = Health::EncounterRecord.new(
        medicaid_id: patient.medicaid_id,
        dob: patient.birthdate,
        gender: patient.gender,
        race: patient.race,
        ethnicity: patient.ethnicity,
        veteran_status: patient.veteran_status,

        date: activity.date_of_activity,
        contact_reached: activity.reached_client,
        mode_of_contact: activity.mode_of_contact,
        provider_name: activity.user_full_name,
        encounter_type: activity.source_type.demodulize.titleize,

        encounter_report_id: self.id,
      )
      if activity.source_type.in?(sources_requiring_preload)
        encounter = activity.source
        return nil unless encounter

        record.assign_attributes(encounter.encounter_report_details)
      else
        source_class = activity.source_type.constantize
        record.assign_attributes(source_class.encounter_report_details)
      end

      record
    end

    def title
      "Patient Encounters Export"
    end

    def url
      warehouse_reports_health_encounters_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    def status
      if started_at.blank?
        "Queued"
      elsif started_at.present? && completed_at.blank?
        if started_at < 24.hours.ago
          'Failed'
        else
          "Running since #{started_at}"
        end
      elsif completed?
        "Complete"
      end
    end

    def completed?
      completed_at.present?
    end

    def activity_scope
      Health::QualifyingActivity.
        in_range(start_date..end_date).
        where.not(source_type: sources_requiring_preload).
        includes(:patient)
    end

    def activity_scope_with_preload
      Health::QualifyingActivity.
        in_range(start_date..end_date).
        where(source_type: sources_requiring_preload).
        includes(:patient, :source)
    end

    private def sources_requiring_preload
      [
        'GrdaWarehouse::HmisForm',
        'Health::SdhCaseManagementNote',
        'Health::SelfSufficiencyMatrixForm',
      ]
    end
  end
end
