###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Ethnicity
  extend ActiveSupport::Concern

  private def ethnicity_buckets
    HudUtility2024.ethnicities.keys
  end

  def ethnicity_title(key)
    HudUtility2024.ethnicity(key)
  end

  def ethnicity_bucket_titles
    ethnicity_buckets.map do |key|
      [
        key,
        ethnicity_title(key),
      ]
    end.to_h
  end

  def ethnicity_bucket(client_ethnicity)
    # mirror Client.race_hispanic_latinaeo
    return :hispanic_latinaeo if client_ethnicity[:HispanicLatinaeo] == 1
    # mirror Client.race_not_hispanic_latinaeo
    return :non_hispanic_latinaeo if client_ethnicity[:HispanicLatinaeo] == 0 && client_ethnicity[:RaceNone].nil?

    :unknown
  end
end
