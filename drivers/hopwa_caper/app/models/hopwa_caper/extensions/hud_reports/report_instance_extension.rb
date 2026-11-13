###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper::HudReports
  module ReportInstanceExtension
    extend ActiveSupport::Concern

    included do
      has_many :hopwa_caper_enrollments, class_name: 'HopwaCaper::Enrollment', dependent: :delete_all, foreign_key: :report_instance_id
      has_many :hopwa_caper_services, class_name: 'HopwaCaper::Service', dependent: :delete_all, foreign_key: :report_instance_id
      has_many :hopwa_caper_funders, class_name: 'HopwaCaper::Funder', dependent: :delete_all, foreign_key: :report_instance_id
    end
  end
end
