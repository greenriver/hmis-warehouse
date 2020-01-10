###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: none
# Control: no PHI

module Health
  class EncounterReport < HealthBase
    has_many :encounter_records

    def populate!
      activity_scope.find_each do |activity|
        patient = activity.patient
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

          source: source_name(activity),
          encounter_type: activity.source_type.demodulize.titleize,
          encounter_report: this
        }
        encounter = activity.source
        record.merge(encounter.encounter_report_details)

        EncounterRecord.create(record)
      end
    end

    def source_name(activity)
      case activity.source_type
      when 'Health::EpicQualifyingActivity'
        'EPIC'
      when 'GrdaWarehouse::HmisForm'
        'ETO'
      else
        'Warehouse'
      end
    end

    def activity_scope
      Health::QualifyingActivity.
        in_range(start_date..end_date).
        includes(:patient)
    end
  end
end