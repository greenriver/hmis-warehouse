###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AppResourceMonitor::CollectStatsJob < ::BaseJob
  def should_enqueue?
    active_config? && run_hour?
  end

  def run_hour?
    DateTime.current.hour == ENV.fetch('COLLECT_STATS_HOUR', 5).to_i
  end

  def active_config?
    active_config.present?
  end

  def active_config
    @active_config ||= GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'app_stats').first
  end

  # To make this work, you'll need to create something like this:
  # GrdaWarehouse::RemoteCredentials::S3.create(slug: 'app_stats', bucket: 'bucket-name', username: 'unknown', password: 'unknown', active: true, path: 'path/to/stats', region: 'us-east-1')
  def perform
    return unless active_config?

    prefix = [active_config.path, [ENV.fetch('CLIENT'), Rails.env].map(&:strip).join('-')].join('/')
    AppResourceMonitor::Report.new.export_to_csv do |directory_name|
      puts prefix
      active_config.s3.upload_directory(directory_name: directory_name, prefix: prefix)
    end
  end
end
