###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::HmisCsvCleanup
  class AppendOrganizationId < Base
    def cleanup!
      organization_batch = []

      organization_scope.find_each do |organization|
        organization.OrganizationName = "#{organization.OrganizationName} (#{organization.OrganizationID})"
        organization.set_source_hash
        organization_batch << organization
      end

      organization_source.import(
        organization_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(organization_source),
          columns: [:OrganizationName, :source_hash],
        },
      )
    end

    def organization_scope
      organization_source.
        where(importer_log_id: @importer_log.id)
    end

    def organization_source
      importable_file_class('Organization')
    end

    def self.description
      'Append the HMIS OrganizationID to the OrganizationName field'
    end

    def self.enable
      {
        import_cleanups: {
          'Organization': ['HmisCsvImporter::HmisCsvCleanup::AppendOrganizationId'],
        },
      }
    end
  end
end
