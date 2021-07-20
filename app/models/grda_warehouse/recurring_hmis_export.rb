###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RecurringHmisExport < GrdaWarehouseBase
    serialize :project_ids, Array
    serialize :project_group_ids, Array
    serialize :organization_ids, Array
    serialize :data_source_ids, Array

    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :s3_secret_access_key, key: ENV['ENCRYPTION_KEY'][0..31], attribute: 'encrypted_s3_secret'

    acts_as_paranoid

    has_many :recurring_hmis_export_links
    has_many :hmis_exports, through: :recurring_hmis_export_links

    def should_run?
      if hmis_exports.exists?
        last_export_finished_on = recurring_hmis_export_links.maximum(:exported_at)
        return Date.current - last_export_finished_on >= every_n_days
      else
        # Don't re-run the export on the day it was requested
        return ! updated_at.today?
      end
    end

    def run
      filter = ::Filters::HmisExport.new(filter_hash)
      filter.adjust_reporting_period
      filter.schedule_job(report_url: nil)
    end

    def s3_present?
      s3_region.present? && s3_bucket.present?
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
      date = Date.current.strftime('%Y%m%d')
      "#{prefix}#{date}-#{report.export_id}.zip"
    end

    def self.available_reporting_ranges
      { 'Dates specified above': 'fixed', '(n) days before run date': 'n_days', 'Month prior to run date': 'month', 'Year prior to run date': 'year' }
    end

    validates :reporting_range, inclusion: { in: available_reporting_ranges.values }

    def aws_s3
      return nil unless s3_present?
      @aws_s3 ||= if self.s3_secret_access_key.present?
        AwsS3.new(
          region: s3_region.strip,
          bucket_name: s3_bucket.strip,
          access_key_id: self.s3_access_key_id.strip,
          secret_access_key: self.s3_secret_access_key
        )
      else
        AwsS3.new(
          region: s3_region.strip,
          bucket_name: s3_bucket.strip
        )
      end
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
        :version,
        :reporting_range,
        :reporting_range_days,
      )
      hash[:recurring_hmis_export_id] = self.id
      return hash
    end

  end
end
