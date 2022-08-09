module Types
  class HmisSchema::ClientInput < BaseInputObject
    description 'HMIS Client input'

    transform_with Types::HmisSchema::Transformers::ClientInputTransformer

    argument :first_name, String, required: false
    argument :middle_name, String, required: false
    argument :last_name, String, required: false
    argument :preferred_name, String, required: false
    argument :name_quality, Types::HmisSchema::Enums::NameDataQuality, required: false
    # TODO: Needs more discussion
    # argument :pronouns, [String], required: false
    argument :dob, String, required: false
    argument :dob_quality, Types::HmisSchema::Enums::DOBDataQuality, required: false
    argument :ssn, String, required: false
    argument :ssn_quality, Types::HmisSchema::Enums::SSNDataQuality, required: false
    argument :gender, [Types::HmisSchema::Enums::Gender], required: false
    argument :race, [Types::HmisSchema::Enums::Race], required: false
    argument :ethnicity, Types::HmisSchema::Enums::Ethnicity, required: false
    argument :veteran_status, Types::HmisSchema::Enums::VeteranStatus, required: false
  end
end
