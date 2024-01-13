###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AppResourceMonitor::CollectStatsJob < ::BaseJob
  def perform
    s3 = GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'app_stats').first&.s3
    return unless s3

    prefix = [ENV.fetch('CLIENT'), Rails.env].map(&:strip).join('-')
    AppResourceMonitor::Report.new.export_to_csv do |directory_name|
      s3.upload_directory(directory_name: directory_name, prefix: prefix)
    end
  end
end
