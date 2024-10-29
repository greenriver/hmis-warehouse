###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::HudReports
  module ReportInstanceExtension
    extend ActiveSupport::Concern

    included do
      has_many :hopwa_caper_enrollments, class_name: 'HopwaCaper::Enrollment', dependent: :delete_all, foreign_key: :report_instance_id
      has_many :hopwa_caper_services, class_name: 'HopwaCaper::Service', dependent: :delete_all, foreign_key: :report_instance_id
    end
  end
end
