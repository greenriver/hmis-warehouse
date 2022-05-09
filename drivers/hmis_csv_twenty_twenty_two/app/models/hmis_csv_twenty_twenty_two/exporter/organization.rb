###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Organization
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def self.adjust_keys(row)
      row.UserID = row.user&.id || 'op-system'
      row.OrganizationID = row.id

      row
    end

    def self.export_scope(project_scope:, export:, hmis_class:, **_)
      export_scope = case export.period_type
      when 3
        hmis_class.where(project_exists_for_organization(project_scope, hmis_class: hmis_class))
      when 1
        hmis_class.where(project_exists_for_organization(project_scope, hmis_class: hmis_class)).modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.distinct.preload(:user)
    end

    def self.project_exists_for_organization project_scope, hmis_class:
      project_scope.where(
        p_t[:OrganizationID].eq(hmis_class.arel_table[:OrganizationID]).
        and(p_t[:data_source_id].eq(hmis_class.arel_table[:data_source_id])),
      ).arel.exists
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Organization::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::Organization,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
      ]
    end
  end
end
