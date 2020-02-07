###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class BackupPlan < HealthBase
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :plan_created_on, Phi::Date
    phi_attr :description, Phi::FreeText
    phi_attr :backup_plan, Phi::FreeText
    phi_attr :phone, Phi::Telephone
    phi_attr :address, Phi::Location
    phi_attr :person, Phi::Name

    belongs_to :patient
    has_many :careplans, through: :patient

    validates_presence_of :description, :backup_plan, :plan_created_on

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end

  end
end