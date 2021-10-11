###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class BackupPlan < HealthBase
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :plan_created_on, Phi::Date, "Date of plan creation"
    phi_attr :description, Phi::FreeText, "Description of backup plan"
    phi_attr :backup_plan, Phi::FreeText, "Name of backup plan"
    phi_attr :phone, Phi::Telephone, "Phone number of patient"
    phi_attr :address, Phi::Location, "Address of patient"
    phi_attr :person, Phi::Name, "Name of patient"

    belongs_to :patient, optional: true
    has_many :careplans, through: :patient

    validates_presence_of :description, :backup_plan, :plan_created_on

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end

  end
end
