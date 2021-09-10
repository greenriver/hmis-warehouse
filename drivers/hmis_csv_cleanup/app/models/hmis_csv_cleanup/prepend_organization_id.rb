###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvCleanup
  class PrependOrganizationId < Base
    def cleanup!
      organization_batch = []

      organization_scope.find_each do |organization|
        organization.OrganizationName = "(#{organization.OrganizationID}) #{organization.OrganizationName}"
        organization.set_source_hash
        organization_batch << organization
      end

      organization_source.import(
        organization_batch,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:OrganizationName, :source_hash],
        },
      )
    end

    def organization_scope
      organization_source.
        where(importer_log_id: @importer_log.id)
    end

    def organization_source
      HmisCsvImporter::Importer::Organization
    end

    def self.description
      'Prepend the HMIS OrganizationID to the OrganizationName field'
    end

    def self.enable
      {
        import_cleanups: {
          'Organization': ['HmisCsvImporter::HmisCsvCleanup::PrependOrganizationId'],
        },
      }
    end
  end
end
