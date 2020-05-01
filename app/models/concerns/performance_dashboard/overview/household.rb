###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Household
  extend ActiveSupport::Concern

  private def household_buckets
    household_types.values + [:unknown]
  end

  def household_bucket_titles
    household_buckets.map do |key|
      [
        key,
        household_type(key),
      ]
    end.to_h
  end

  def household_bucket(individual_adult, age, other_clients_under_18, children_only)
    return :without_children if individual_adult
    return :only_children if children_only
    return :with_children if age.present? && age > 17 && other_clients_under_18.positive?

    :unknown
  end

  def household_query(key)
    return '0=1' unless key

    @household_queries ||= {
      without_children: she_t[:individual_adult].eq(true).or(she_t[:age].eq(nil)),
      with_children: she_t[:age].gt(17).and(she_t[:other_clients_under_18].gt(0)),
      only_children: she_t[:children_only].eq(true),
    }
    @household_queries[key.to_sym]
  end
end
