###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::Enrollment', primary_key: [:EnrollmentID, :data_source_id], foreign_key: [:EnrollmentID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::Enrollment', primary_key: [:EnrollmentID, :data_source_id], foreign_key: [:EnrollmentID, :data_source_id]
    end

    # Latest coverage end, min(effective_export_end_date, ExportEndDate), among the exports whose
    # imports included this enrollment. Nil when the newest import year has no per-year method
    # (2022 and 2024 always migrate to 2026 before import) or no staging rows survive.
    # effective_export_end_date is written at the end of ingest!, so an export without one is from an
    # import that has not finished and is skipped.
    def import_coverage_end_date
      year = most_recent_import_year
      return unless year

      method_name = "import_coverage_end_date_#{year}"
      public_send(method_name) if respond_to?(method_name)
    end

    private def import_coverage_end_date_for(staging_items, staging_export_class)
      staging_exports = staging_export_class.where(importer_log_id: staging_items.select(:importer_log_id))
      GrdaWarehouse::Hud::Export.
        where(data_source_id: data_source_id, ExportID: staging_exports.select(:ExportID)).
        where.not(effective_export_end_date: nil).
        pluck(:effective_export_end_date, :ExportEndDate).
        filter_map { |effective, export_end| [effective, export_end].compact.min }.
        max
    end
  end
end
