###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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

  def household_bucket(enrollment)
    return :unknown if enrollment.age.blank?
    return :without_children if enrollment.age > 17 && enrollment.other_clients_under_18.zero?
    return :only_children if enrollment.age < 18 && enrollment.other_clients_between_18_and_25.zero? && enrollment.other_clients_over_25.zero?
    return :with_children if (enrollment.age > 17 && enrollment.other_clients_under_18.positive?) || (enrollment.age < 18 && (enrollment.other_clients_between_18_and_25.positive? || enrollment.other_clients_over_25.positive?))

    :unknown
  end

  def household_query(key)
    return '0=1' unless key

    @household_queries ||= {
      without_children: she_t[:other_clients_under_18].eq(0).and(she_t[:age].gteq(18).or(she_t[:age].eq(nil))),
      with_children: she_t[:age].gteq(18).and(she_t[:other_clients_under_18].gt(0)).
        or(she_t[:age].lt(18).
            and(
              she_t[:other_clients_between_18_and_25].gt(0).
              or(she_t[:other_clients_over_25].gt(0)),
            )),
      only_children: she_t[:age].lt(18).and(she_t[:other_clients_between_18_and_25].eq(0)).and(she_t[:other_clients_over_25].eq(0)),
    }
    @household_queries[key.to_sym]
  end
end
