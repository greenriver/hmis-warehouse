###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Client < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Client
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
      }
    end

    # We never delete clients during the import, so make sure we find all existing clients in this data source
    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      return none unless project_ids.present?

      GrdaWarehouse::Hud::Client.where(data_source_id: data_source_id)
    end

    # Don't ever mark these for deletion, these get cleaned up if they don't have any source enrollments
    # def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
    # end

    # We don't mark these as dead, so the existing data is just those that match the appropriate scope
    # def self.existing_destination_data(data_source_id:, project_ids:, date_range:)
    #   involved_warehouse_scope(
    #     data_source_id: data_source_id,
    #     project_ids: project_ids,
    #     date_range: date_range,
    #   ).joins(enrollments: :project).
    #     merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
    #     merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range))
    # end
  end
end
