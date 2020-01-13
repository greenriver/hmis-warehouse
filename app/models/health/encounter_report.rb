###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: none
# Control: no PHI, PHI is in encounter_records

module Health
  class EncounterReport < HealthBase
    include Rails.application.routes.url_helpers

    has_many :encounter_records

    def run_and_save!
      update(started_at: Time.current)
      activity_scope.find_each do |activity|
        patient = activity.patient
        next unless patient

        record = {
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

          encounter_report: self
        }
        encounter = activity.source
        next unless encounter

        record.merge(encounter.encounter_source)
        record.merge(encounter.encounter_report_details)

        Health::EncounterRecord.create(record)
      end
      update(completed_at: Time.current)
    end

    def title
      "Patient Encounters Export"
    end

    def url
      warehouse_reports_health_encounters_url(host: ENV.fetch('FQDN'))
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
        includes(:patient, :source)
    end
  end
end