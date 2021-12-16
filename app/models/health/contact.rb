###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Contact < HealthBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, 'ID of contact'
    phi_attr :name, Phi::SmallPopulation, 'Name of contact'
    phi_attr :email, Phi::SmallPopulation, 'Email of contact'
    phi_attr :phone, Phi::SmallPopulation, 'Phone number of contact'
    phi_attr :category, Phi::SmallPopulation, 'Category of contact'
    phi_attr :description, Phi::SmallPopulation, 'Description of contact'

    belongs_to :patient, optional: true
    belongs_to :source, polymorphic: true

    def self.sync!(force = false)
      contact_sources.each do |klass|
        import!(
          klass.as_health_contacts(force),
          on_duplicate_key_update: {
            conflict_target: [:client_id, :source_id, :source_type],
          },
        )
      end
    end

    def self.contact_sources
      [
        Health::Team::Member,
        GrdaWarehouse::ClientContact,
      ]
    end
  end
end
