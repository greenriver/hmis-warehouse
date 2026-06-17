###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Cleanup
  class ExpireImportersJob < ExpireBaseJob
    protected

    def log_id_field
      :importer_log_id
    end

    def log_model
      ::HmisCsvImporter::Importer::ImporterLog
    end

    def models
      active_data_lake_modules.flat_map do |mod|
        raise "#{mod.name} registered in hmis_data_lakes but does not implement expiring_importer_classes" unless mod.respond_to?(:expiring_importer_classes)

        mod.expiring_importer_classes
      end
    end
  end
end
