module Types
  class HmisSchema::ClientInput < BaseInputObject
    description 'HMIS Client input'

    transform_with Types::HmisSchema::Transformers::ClientInputTransformer

    argument :first_name, String, required: false
    argument :middle_name, String, required: false
    argument :last_name, String, required: false
    argument :preferred_name, String, required: false
    argument :name_suffix, String, required: false
    argument :name_data_quality, Types::HmisSchema::Enums::Hud::NameDataQuality, required: false
    # TODO: Needs more discussion
    # argument :pronouns, [String], required: false
    argument :dob, String, required: false
    argument :dob_data_quality, Types::HmisSchema::Enums::Hud::DOBDataQuality, required: false
    argument :ssn, String, required: false
    argument :ssn_data_quality, Types::HmisSchema::Enums::Hud::SSNDataQuality, required: false
    argument :gender, [Types::HmisSchema::Enums::Gender], required: false
    argument :race, [Types::HmisSchema::Enums::Race], required: false
    argument :ethnicity, Types::HmisSchema::Enums::Hud::Ethnicity, required: false
    argument :veteran_status, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData, required: false
  end
end
