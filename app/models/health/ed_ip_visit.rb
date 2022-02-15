###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisit < HealthBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :admit_date, Phi::Date, 'Date of admission'
    phi_attr :encounter_major_class, Phi::SmallPopulation, 'Emergency or Inpatient'

    belongs_to :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id, optional: true
    belongs_to :loaded_ed_ip_visit, optional: true

    scope :valid, -> do
      where.not(admit_date: nil)
    end

    # Populate table with pre-existing data
    def self.populate!
      Health::EdIpVisitFile.find_each do |file|
        file.ingest!(Health::LoadedEdIpVisit.from_file(file))
      end
    end
  end
end
