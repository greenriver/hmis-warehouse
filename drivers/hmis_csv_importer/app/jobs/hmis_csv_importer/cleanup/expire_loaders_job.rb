###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Cleanup
  class ExpireLoadersJob < ExpireBaseJob
    protected

    def log_id_field
      :loader_id
    end

    def log_model
      ::HmisCsvImporter::Loader::LoaderLog
    end

    def models
      active_data_lake_modules.flat_map do |mod|
        raise "#{mod.name} registered in hmis_data_lakes but does not implement expiring_loader_classes" unless mod.respond_to?(:expiring_loader_classes)

        mod.expiring_loader_classes
      end
    end
  end
end
