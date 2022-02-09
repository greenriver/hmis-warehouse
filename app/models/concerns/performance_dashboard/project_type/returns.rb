###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::Returns
  extend ActiveSupport::Concern

  # A return is when a client has an exit to a permanent destination
  # followed by an entry into ES, SH, or SO after more than 7 days post exit

  # Find the first exit to a permanent destination
  def permanent_exits
    @permanent_exits ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      {}.tap do |exits|
        exits_current_period.
          order(last_date_in_program: :asc).
          pluck(:client_id, she_t[:id], she_t[:destination], :last_date_in_program).
          each do |c_id, en_id, destination, last_date_in_program|
            next unless HUD.permanent_destinations.include?(destination)

            exits[c_id] = {
              exit_id: en_id,
              exit_date: last_date_in_program,
            }
          end
      end
    end
  end

  # Find any entries into ES, SH, or SO more than 7 days after the first exit to
  # a permanent destination, look forward as far as necessary.
  # NOTE: this only looks for the first re-entry after the first exit to a permanent
  # destination, potentially someone exited more than once within the report range
  # and returned from that enrollment...
  def homeless_re_entries
    @homeless_re_entries ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      {}.tap do |entries|
        p_exits = permanent_exits
        entries_current_period.where(first_date_in_program: (@start_date..Date.current)).
          hud_homeless.
          where(client_id: p_exits.keys). # limit to those with an exit
          order(first_date_in_program: :asc).
          pluck(:client_id, she_t[:id], :first_date_in_program).
          each do |c_id, en_id, first_date_in_program|
            permanent_exit = p_exits[c_id]
            permanent_exit_date = permanent_exit[:exit_date]
            # Collect enrollments where the client is returning after 7 days or more
            # Find the first entry after the permanent exit
            next if first_date_in_program < permanent_exit_date
            next unless permanent_exit_date + 7.days < first_date_in_program

            days_to_return = (first_date_in_program - permanent_exit_date).to_i
            entries[c_id] ||= {
              entry_id: en_id,
              entry_date: first_date_in_program,
              days_to_return: days_to_return,
              returns_bucket: returns_bucket(days_to_return),
            }.merge(permanent_exit)
          end
        p_exits.reject { |c_id, _| entries.key?(c_id) }.each do |c_id, permanent_exit|
          entries[c_id] ||= permanent_exit.merge(returns_bucket: :did_not_return)
        end
      end
    end
  end

  def returned_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      homeless_re_entries.values.flatten.count
    end
  end

  def returns_data_for_chart
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      columns = [@filter.date_range_words]
      columns += returns_buckets.map do |bucket|
        homeless_re_entries.values.map { |en| en[:returns_bucket] }.count(bucket)
      end
      categories = returns_bucket_titles.values
      {
        columns: columns,
        categories: categories,
        avg_columns: returns_avg_columns,
      }
    end
  end

  private def returns_avg_columns
    did_not_return_count = homeless_re_entries.count { |_, d| d[:returns_bucket] == :did_not_return }
    returned_count = homeless_re_entries.count - did_not_return_count
    [
      [
        "Returned (#{number_with_delimiter(returned_count)})",
        returned_count,
      ],
      [
        "Did not Return (#{did_not_return_count})",
        did_not_return_count,
      ],
    ]
  end

  private def returns_buckets
    returns_bucket_titles.keys
  end

  def returns_bucket_titles
    {
      less_than_six_months: '< 6 months',
      six_to_twelve_months: '6 to 12 months',
      one_to_two_years: '1 to 2 years',
      over_two_years: '> 2 years',
      did_not_return: 'Did not return',
    }.freeze
  end

  def returns_bucket(time)
    if time < 180
      :less_than_six_months
    elsif time >= 181 && time <= 365
      :six_to_twelve_months
    elsif time >= 366 && time <= 730
      :one_to_two_years
    elsif time >= 731
      :over_two_years
    end
  end

  private def returns_details(options)
    return {} unless options[:sub_key].present?

    sub_key = options[:sub_key]&.to_sym
    ids = homeless_re_entries.values.
      select { |en| en[:returns_bucket] == sub_key }.
      map { |en| [en[:entry_id], en[:exit_id]] }.
      flatten
    details = report_scope_source.joins(:client, :enrollment).
      where(id: ids).
      order(c_t[:LastName].asc, c_t[:FirstName].asc, first_date_in_program: :asc)
    details.pluck(*detail_columns(options).values).
      each_with_index.map { |r, i| [i, r] }.to_h # Details only uses the values, but expects it to be keyed, so just key with index
  end

  private def returns_detail_headers(options)
    detail_columns(options).keys
  end
end
