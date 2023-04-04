###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Organization < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Organization
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_organizations'

    has_one :destination_record, **hud_assoc(:OrganizationID, 'Organization')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      warehouse_class.importable.joins(:projects).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Organization
    end

    # Don't ever mark these for deletion
    # def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
    # end

    # We don't mark these as dead, so the existing data is just those that match the appropriate scope
    # def self.existing_destination_data(data_source_id:, project_ids:, date_range:)
    #   involved_warehouse_scope(
    #     data_source_id: data_source_id,
    #     project_ids: project_ids,
    #     date_range: date_range,
    #   )
    # end

    def self.hmis_validations
      {
        OrganizationID: [
          class: HmisCsvValidation::NonBlank,
        ],
        OrganizationName: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
        VictimServicesProvider: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility.yes_no_missing_options.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
