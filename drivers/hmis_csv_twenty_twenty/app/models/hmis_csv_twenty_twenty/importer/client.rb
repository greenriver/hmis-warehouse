###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Client < GrdaWarehouse::Hud::Base
    include ImportConcern
    include ::HMIS::Structure::Client
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_clients'

    has_one :destination_record, **hud_assoc(:ClientID, 'Client')

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
            arguments: { valid_options: HUD.name_data_quality_options.keys },
          },
        ],
        SSNDataQuality: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.ssn_data_quality_options.keys },
          },
        ],
      }
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      GrdaWarehouse::Hud::Client.where(data_source_id: data_source_id)
    end

    # Don't ever mark these for deletion, these get cleaned up if they don't have any source enrollments
    def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
    end
  end
end
