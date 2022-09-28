module Types
  class HmisSchema::OrganizationInput < BaseInputObject
    description 'HMIS Organization input'

    argument :organization_name, String, required: false
    yes_no_missing_argument :victim_service_provider, required: false
    argument :description, String, required: false
    argument :contact_information, String, required: false

    def to_params
      to_h
    end
  end
end
