###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Entering # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  def entering
    entries.distinct
  end

  def entering_total_count
    entering.select(:client_id).count
  end

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_age
    buckets = age_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    entering.order(first_date_in_program: :desc).
      pluck(:client_id, :age, :first_date_in_program).each do |id, age, _|
      buckets[age_bucket(age)] << id unless counted.include?(id)
      counted << id
    end
    buckets
  end

  def entering_by_age_data_for_chart
    @entering_by_age_data_for_chart ||= begin
      columns = [(@start_date..@end_date).to_s]
      columns += entering_by_age.values.map(&:count)
      {
        columns: columns,
        categories: entering_by_age.keys.map(&:to_s).map(&:humanize),
      }
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def entering_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      entering_by_age[sub_key]
    else
      entering_by_age.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(age_query(sub_key)) if sub_key
    details.pluck(*entering_detail_columns(options).values).
      index_by(&:first)
  end

  private def entering_detail_columns(options)
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

  private def entering_detail_headers(options)
    entering_detail_columns(options).keys
  end
end
