###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Client < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Client
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_clients'

    has_one :destination_record, **hud_assoc(:PersonalID, 'Client')

    def self.clean_row_for_import(row, deidentified:)
      row = deidentify_client_name(row) if deidentified
      row['SSN'] = row['SSN'].to_s[0..8] # limit SSNs to 9 characters
      row
    end

    def self.deidentify_client_name(row)
      row['FirstName'] = "First_#{row['PersonalID']}"
      row['LastName'] = "Last_#{row['PersonalID']}"
      row
    end

    def self.hmis_validations
      {
        NameDataQuality: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.name_data_quality_options.keys.map(&:to_s).freeze },
          },
        ],
        SSNDataQuality: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.ssn_data_quality_options.keys.map(&:to_s).freeze },
          },
        ],
        DOBDataQuality: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.dob_data_quality_options.keys.map(&:to_s).freeze },
          },
        ],
        Ethnicity: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.ethnicities.keys.map(&:to_s).freeze },
          },
        ],
        Gender: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.genders.keys.map(&:to_s).freeze },
          },
        ],
        VeteranStatus: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.no_yes_reasons_for_missing_data_options.keys.map(&:to_s).freeze },
          },
        ],
      }
    end

    # We never delete clients during the import, so make sure we find all existing clients in this data source
    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.where(data_source_id: data_source_id)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Client
    end
  end
end
