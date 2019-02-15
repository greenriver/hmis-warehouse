module GrdaWarehouse
  class RecurringHmisExport < GrdaWarehouseBase
    serialize :project_ids, Array
    serialize :project_group_ids, Array
    serialize :organization_ids, Array
    serialize :data_source_ids, Array

    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY']
    attr_encrypted :s3_secret_access_key, key: ENV['ENCRYPTION_KEY'], attribute: 'encrypted_s3_secret'

    has_many :recurring_hmis_export_links
    has_many :hmis_exports, through: :recurring_hmis_export_links

    def should_run?
      if hmis_exports.present?
        last_export_finished_on = recurring_hmis_export_links.last.exported_at
        return Date.today - last_export_finished_on >= every_n_days
      else
        # Don't re-run the export on the day it was requested
        return ! updated_at.today?
      end
    end

    def run
      filter = ::Filters::HmisExport.new(filter_hash)
      filter.adjust_reporting_period
      ::WarehouseReports::HmisSixOneOneExportJob.perform_later(filter.options_for_hmis_export(:six_one_one).as_json,
        report_url: nil)
    end

    def s3_present?
      s3_region.present? && s3_bucket.present? && s3_access_key_id.present? && s3_secret_access_key.present?
    end

    def s3_valid?
      return aws_s3.present?
    end

    def store(report)
      if s3_valid?
        aws_s3.store(content: report.content, name: object_name(report))
      end
    end

    def object_name(report)
      prefix = ''
      if s3_prefix.present?
        prefix = "#{s3_prefix.strip}-"
      end
      date = Date.today.strftime('%Y%m%d')
      "#{prefix}#{date}-#{report.export_id}.zip"
    end

    def self.available_reporting_ranges
      { 'Dates specified above': 'fixed', '(n) days before run date': 'n_days', 'Month prior to run date': 'month', 'Year prior to run date': 'year' }
    end

    validates :reporting_range, inclusion: { in: available_reporting_ranges.values }

    def aws_s3
      return nil unless s3_present?
      @awsS3 ||= AwsS3.new(region: s3_region.strip,
          bucket_name: s3_bucket.strip,
          access_key_id: s3_access_key_id.strip,
          secret_access_key: s3_secret_access_key.strip )
    end

    def self.available_s3_regions
      [
        'us-east-1',
        'us-east-2',
        'us-west-1',
        'us-west-2',
        'ap-northeast-1',
        'ap-northeast-2',
        'ap-south-1',
        'ap-southeast-1',
        'ap-southeast-2',
        'ca-central-1',
        'eu-central-1',
        'eu-west-1',
        'eu-west-2',
        'eu-west-3',
        'sa-east-1',
      ]
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

        :reporting_range,
        :reporting_range_days,
      )
      hash[:recurring_hmis_export_id] = self.id
      return hash
    end

  end
end
