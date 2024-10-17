###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Importer
  class Client < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Client
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2024_clients'
    self.primary_key = 'id'

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
        PersonalID: [
          class: HmisCsvValidation::NonBlank,
        ],
        NameDataQuality: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.name_data_quality_options.keys.map(&:to_s).freeze },
          },
        ],
        SSNDataQuality: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.ssn_data_quality_options.keys.map(&:to_s).freeze },
          },
        ],
        DOBDataQuality: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.dob_data_quality_options.keys.map(&:to_s).freeze },
          },
        ],
        VeteranStatus: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_reasons_for_missing_data_options.keys.map(&:to_s).freeze },
          },
        ],
        # TODO: Enforce Race and Gender constraints?
        Woman: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        Man: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        NonBinary: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        CulturallySpecific: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        Transgender: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        Questioning: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        DifferentIdentity: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        GenderNone: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.race_gender_none_options.keys.map(&:to_s).freeze },
          },
        ],
        AmIndAKNative: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        Asian: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        BlackAfAmerican: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        HispanicLatinaeo: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        MidEastNAfrican: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        NativeHIPacific: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        White: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.no_yes_options.keys.map(&:to_s).freeze },
          },
        ],
        RaceNone: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.race_gender_none_options.keys.map(&:to_s).freeze },
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
