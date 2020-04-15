###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Entering::Household # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_household
    buckets = household_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    entering.
      joins(:client).
      order(first_date_in_program: :desc).
      pluck(:client_id, :individual_adult, :age, :other_clients_under_18, :children_only, :first_date_in_program).each do |id, individual_adult, age, other_clients_under_18, children_only, _| # rubocop:disable Metrics/ParameterLists
      buckets[household_bucket(individual_adult, age, other_clients_under_18, children_only)] << id unless counted.include?(id)
      counted << id
    end
    buckets
  end

  def entering_by_household_data_for_chart
    @entering_by_household_data_for_chart ||= begin
      columns = [(@start_date..@end_date).to_s]
      columns += entering_by_household.values.map(&:count).drop(1) # ignore :all
      categories = entering_by_household.keys.map do |type|
        household_type(type)
      end.drop(1) # ignore :all
      {
        columns: columns, # ignore :all
        categories: categories, # ignore :all
      }
    end
  end

  private def entering_by_household_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      entering_by_household[sub_key]
    else
      entering_by_household.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(household_query(sub_key)) if sub_key
    details.pluck(*entering_detail_columns(options).values).
      index_by(&:first)
  end
end
