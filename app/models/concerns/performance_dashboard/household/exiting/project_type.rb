###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Exiting::ProjectType
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def exiting_by_project_type
    @exiting_by_project_type ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = project_type_buckets.map { |b| [b, []] }.to_h
      counted = {}
      exiting.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:household_id, she_t[project_type_col], :first_date_in_program).each do |id, project_type, _|
          counted[project_type_bucket(project_type)] ||= Set.new
          buckets[project_type_bucket(project_type)] << id unless counted[project_type_bucket(project_type)].include?(id)
          counted[project_type_bucket(project_type)] << id
        end
      buckets
    end
  end

  def exiting_by_project_type_data_for_chart
    @exiting_by_project_type_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += exiting_by_project_type.values.map(&:count)
      categories = exiting_by_project_type.keys
      categories &= GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values.flatten
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HUD.project_type(s)] }.to_h,
          chosen: @project_types,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def exiting_by_project_type_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      exiting_by_project_type[sub_key]
    else
      exiting_by_project_type.values.flatten
    end
    details = exiting.joins(:client).
      where(household_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(project_type_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      map do |row|
        row[-1] = "#{HUD.project_type(row.last)} (#{row.last})"
        row
      end.
      index_by(&:first)
  end
end
