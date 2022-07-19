module Types
  class HmisSchema::ClientSearchInput < BaseInputObject
    description 'HMIS Client search input'

    argument :id, ID, 'Client primary key', required: false
    argument :text_search, String, 'Omnisearch string', required: false
    argument :personal_id, String, required: false
    argument :warehouse_id, String, required: false
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :preferred_name, String, required: false
    argument :ssn_serial, String, 'Last 4 digits of SSN', required: false
    argument :dob, String, 'Date of birth as format yyyy-mm-dd', required: false
    argument :projects, [ID], required: false
    argument :organizations, [ID], required: false

    def to_params
      to_h
    end
  end
end
