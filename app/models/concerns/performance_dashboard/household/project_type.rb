###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::ProjectType
  extend ActiveSupport::Concern

  private def project_type_buckets
    buckets = HUD.project_types.keys
    buckets & GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values.flatten
  end

  def project_type_bucket_titles
    project_type_buckets.map do |key|
      [
        key,
        HUD.project_type(key),
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
