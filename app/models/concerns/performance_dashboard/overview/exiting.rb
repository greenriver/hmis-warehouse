###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  def exiting
    exits.distinct
  end

  def exiting_total_count
    exiting.select(:client_id).count
  end

  def exiting_by_age
    buckets = age_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    exiting.order(first_date_in_program: :desc).
      pluck(:client_id, :age, :first_date_in_program).each do |id, age, _|
      buckets[age_bucket(age)] << id unless counted.include?(id)
      counted << id
    end
    buckets
  end

  def exiting_by_age_data_for_chart
    @exiting_by_age_data_for_chart ||= begin
      columns = [(@start_date..@end_date).to_s]
      columns += exiting_by_age.values.map(&:count)
      {
        columns: columns,
        categories: exiting_by_age.keys.map(&:to_s).map(&:humanize),
      }
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def exiting_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      exiting_by_age[sub_key]
    else
      exiting_by_age.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(age_query(sub_key)) if sub_key
    details.pluck(*exiting_detail_columns(options).values).
      index_by(&:first)
  end

  private def exiting_detail_columns(options)
    columns = {
      'Client ID' => she_t[:client_id],
      'First Name' => c_t[:FirstName],
      'Last Name' => c_t[:LastName],
      'Project' => she_t[:project_name],
      'Entry Date' => she_t[:first_date_in_program],
      'Exit Date' => she_t[:last_date_in_program],
    }
    # Add any additional columns
    columns['Age'] = she_t[:age] if options[:age]
    columns
  end

  private def exiting_detail_headers(options)
    exiting_detail_columns(options).keys
  end
end
