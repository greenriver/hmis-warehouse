###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Equipment < HealthBase
    acts_as_paranoid

    phi_patient :patient_id

    phi_attr :effective_date, Phi::Date, "Effective date of equipment"
    phi_attr :provider, Phi::FreeText, "Name of provider"
    phi_attr :comments, Phi::FreeText, "Comments on equipment"

    has_many :careplans
    belongs_to :patient, optional: true

    validates_presence_of :item
    validates :quantity, numericality: { only_integer: true, allow_blank: true }
    def self.available_items
      [
        'Diapers',
        'Pullups',
        'Liners',
        'Disposable Under pad /Chux',
        'Reusable bed size pad',
        'Reusable chair pad',
        'Enteral and Parenteral Formula',
        'Hearing Aid Batteries',
        'Prosthetics, Orthotics, and Orthopedic Footwear',
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
