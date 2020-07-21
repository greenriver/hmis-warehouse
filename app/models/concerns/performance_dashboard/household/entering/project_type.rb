###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Entering::ProjectType
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_project_type
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = project_type_buckets.map { |b| [b, []] }.to_h
      counted = {}
      entering.
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

  def entering_by_project_type_data_for_chart
    @entering_by_project_type_data_for_chart ||= begin
      columns = [date_range_words]
      columns += entering_by_project_type.values.map(&:count)
      categories = entering_by_project_type.keys
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

  private def entering_by_project_type_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      entering_by_project_type[sub_key]
    else
      entering_by_project_type.values.flatten
    end
    details = entries_current_period.joins(:client).
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
