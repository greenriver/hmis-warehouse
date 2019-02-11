module GrdaWarehouse
  class RecurringHmisExport < GrdaWarehouseBase
    serialize :project_ids, Array
    serialize :project_group_ids, Array
    serialize :organization_ids, Array
    serialize :data_source_ids, Array

    belongs_to :hmis_export

    def should_run?
      if hmis_export.present?
        export_finished_on = hmis_export.updated_at.to_date
        return Date.today - export_finished_on >= every_n_days
      else
        # Don't re-run the export on the day it was requested
        return ! updated_at.today?
      end
    end

    def run
      filter = ::Filters::HmisExport.new(filter_hash)
      adjust_reporting_period(filter)
      ::WarehouseReports::HmisSixOneOneExportJob.perform_later(filter.options_for_hmis_export(:six_one_one).as_json,
        report_url: nil)
    end

    def filter_hash
      hash = self.slice(
        :start_date,
        :end_date,
        :hash_status,
        :period_type,
        :directive,
        :include_deleted,
        :project_ids,
        :project_group_ids,
        :organization_ids,
        :data_source_ids,
        :user_id,
        :faked_pii,
      )
      hash[:recurring_hmis_export_id] = self.id
      return hash
    end
  end
end
