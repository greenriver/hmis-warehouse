class MigrateExistingRecurringExportConfig < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::RecurringHmisExport.find_each do |export|
      filter = ::Filters::HmisExport.new(
        user_id: export.user_id,
        version: export.version,
        start_date: export.start_date,
        end_date: export.end_date,
        hash_status: export.hash_status,
        period_type: export.period_type,
        include_deleted: export.include_deleted,
        directive: export.directive,
        faked_pii: export.faked_pii,
        confidential: export.confidential,
        project_ids: export.project_ids,
        project_group_ids: export.project_group_ids,
        organization_ids: export.organization_ids,
        data_source_ids: export.data_source_ids,
      )
      export.update(options: filter.to_h)
    end
  end
end
