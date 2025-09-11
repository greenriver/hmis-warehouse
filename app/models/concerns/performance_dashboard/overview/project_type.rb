###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceDashboard::Overview::ProjectType
  extend ActiveSupport::Concern

  private def project_type_buckets
    buckets = HudUtilityCurrent.project_types.keys
    buckets & HudUtilityCurrent.performance_reporting.values.flatten
  end

  def project_type_bucket_titles
    project_type_buckets.map do |key|
      [
        key,
        HudUtilityCurrent.project_type(key),
      ]
    end.to_h
  end

  def project_type_bucket(project_type)
    project_type
  end

  def project_type_query(key)
    return '0=1' unless key

    she_t[project_type_col].eq(key.to_i)
  end

  private def project_type_col
    GrdaWarehouse::ServiceHistoryEnrollment.project_type_column
  end
end
