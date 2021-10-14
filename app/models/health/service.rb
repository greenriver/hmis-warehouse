###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Service < HealthBase
    acts_as_paranoid

    phi_patient :patient_id

    phi_attr :effective_date, Phi::Date
    phi_attr :date_requested, Phi::Date
    phi_attr :end_date, Phi::Date
    phi_attr :item, Phi::FreeText
    phi_attr :comments, Phi::FreeText

    has_many :careplans
    belongs_to :patient, optional: true

    validates_presence_of :service_type

    def self.available_types
      [
        'Primary Care Physician (PCP)',
        'Home Health',
        'Psychiatrist',
        'Therapist',
        'Care Coordinator (MBHP, SCO, One Care)',
        'Specialist: (Endocrinology, Cardiology, Neurology, Dermatology, Pulmonary)',
        'Guardian (Indicate Type:  (Permanent, Roger’s, Medical, Conservatorship, Temporary, Full)',
        'Rep Payee',
        'Social Support (i.e. informal, caregiver, family)',
        'Community Based Flexible Supports (CBFS)',
        'Long-term Services and Supports Community Partner (LTSS CP)',
        'Housing Provider',
        'Day Services Provider',
        'Job Coach / Employment',
        'Peer Support / CHW',
        'Department of Transitional Assistance (DTA)',
        'Veterans Affairs',
        'Probation/Parole',
        'Other',
      ]
    end

    def self.available_stati
      [
        'Requested',
        'Active',
        'Expired',
        'Issue',
        'Denied',
      ]
    end

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end

  end
end
