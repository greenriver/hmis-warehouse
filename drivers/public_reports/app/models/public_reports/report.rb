###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-s3'
module PublicReports
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    include WarehouseReports::S3Toolset
    include Filter::FilterScopes
    include ArelHelper
    include Reporting::Status
    include WarehouseReports::Publish

    MIN_THRESHOLD = 11

    belongs_to :user, optional: true
    scope :viewable_by, ->(user) do
      return current_scope if user.can_view_all_reports?

      where(user_id: user.id)
    end

    scope :diet, -> do
      select(attribute_names - ['html', 'precalculated_data'])
    end

    def settings
      @settings ||= PublicReports::Setting.first_or_create
    end

    def chart_color_pattern(category = nil)
      settings.color_pattern(category).to_json.html_safe
    end

    def chart_color_shades(category = nil)
      (settings.color_shades(category) + ['#FFFFFF']).reverse
    end

    def filter_object
      @filter_object ||= begin
        f = ::Filters::FilterBase.new(user_id: user.id).set_from_params(filter['filters'].merge(enforce_one_year_range: false).with_indifferent_access)
        # Enforce that public reports can't be run for partial months
        # Always move the end date back to the end of last month if it's beyond that date
        # Enforce that the start date is always the beginning of the month
        end_of_last_month = if Date.current == Date.current.end_of_month
          Date.current
        else
          (Date.current - 1.months).end_of_month
        end
        f.end = f.end.end_of_month
        f.end = end_of_last_month if f.end > end_of_last_month
        f.start = f.start.beginning_of_month
        f
      end
    end

    def known_params
      [
        :start,
        :end,
        :coc_codes,
        :project_ids,
        :organization_ids,
        :data_source_ids,
        :project_type_numbers,
        :project_group_ids,
        :hoh_only,
      ]
    end

    def font_path
      settings.font_path
    end

    def font_family
      settings.font_family
    end

    def font_size
      settings.font_size
    end

    def font_weight
      settings.font_weight
    end

    private def start_report
      update(started_at: Time.current, state: :started)
    end

    private def complete_report
      update(completed_at: Time.current, state: 'pre-computed')
    end

    def enforce_min_threshold(data, key) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      case key
      when 'min_threshold'
        data = MIN_THRESHOLD if data.positive? && data < MIN_THRESHOLD
        data
      when 'homeless_households', 'homeless_clients'
        value = data[key]
        return 0 if value.zero?
        return number_with_delimiter(value) if value > 100

        under_threshold
      when 'unsheltered_percent'
        unsheltered_count = data['unsheltered_clients'].to_f || 0.0
        sheltered_count = data['homeless_clients'] || 0
        percent = if unsheltered_count.zero? || sheltered_count.zero?
          0
        elsif unsheltered_count > 100 && sheltered_count > 100
          ((unsheltered_count / sheltered_count) * 100).round
        else
          ((unsheltered_count / sheltered_count) * 100).round(-1)
        end
        "#{percent}%"
      when 'pit_chart', 'inflow_outflow'
        return data if data.zero?
        return data if data > 100

        100
      when 'hoh_pit_chart'
        return data if data.zero?
        return data if data > 20

        20
      when 'location'
        # return percentages for each instead of raw counts
        (sheltered, unsheltered) = data
        total = sheltered + unsheltered
        return [0, 0] if total.zero? || (total < 100 && data.any? { |m| m < 11 })

        sheltered = ((sheltered.to_f / total) * 100).round
        unsheltered = ((unsheltered.to_f / total) * 100).round
        # if the total is < 1,000, return numbers rounded to the nearest 10%, ensuring that the parts total 100
        if total < 1_000
          sheltered = sheltered.round(-1)
          unsheltered = unsheltered.round(-1)
          diff = (sheltered + unsheltered) - 100
          if sheltered > unsheltered
            sheltered -= diff
          else
            unsheltered -= diff
          end
        end
        [sheltered, unsheltered]
      when 'donut', 'household_type'
        # return percentages for each instead of raw counts
        total = data.sum
        return data.map { |_| 0 } if total.zero? || (total < 100 && data.any? { |m| m < 11 })

        # convert counts to percents
        data.map! do |count|
          ((count.to_f / total) * 100).round
        end

        # if the total is < 1,000, return numbers rounded to the nearest 10%, ensuring that the parts total 100
        if total < 1_000
          data.map! do |count|
            count.round(-1)
          end
          diff = data.sum - 100
          max = data.max
          # correct any discrepancies caused by rounding by subtracting from the largest
          data.each.with_index do |count, i|
            if count == max
              data[i] -= diff
              break
            end
          end
        end
        data
      when 'need_map'
        # Convert all rates to the upper limit of the range of map_colors the rate falls into
        # ensure overall population is at least 100
        # {"homeless_map"=>{"2018-01-01"=>{"ROCKPORT"=>{"count"=>62, "overall_population"=>500, "rate"=>12.4}, "COLRAIN"=>{"count"=>95, "overall_population"=>500, "rate"=>19.0}...
        data.each do |_, date_data|
          date_data.each do |_, count_data|
            count_data.each do |_, c_data|
              c_data[:count] = 'less than 100' if c_data[:count].positive? && c_data[:count] < 100
              top_of_range = map_colors.values.detect { |bucket| bucket[:range].cover?(c_data[:rate]) }.try(:[], :range)&.last
              c_data[:rate] = top_of_range || 0 unless top_of_range == 100
            end
          end
        end
      when 'homeless_row'
        data.each do |_, chart_data|
          next unless chart_data['data'].map(&:last).any? { |count| count < MIN_THRESHOLD }

          chart_data['data'].each do |row|
            row[1] = 0
          end
          chart_data['data'] << ['Redacted', 100]
        end
      when 'chronic_percents'
        (chronic_count, total_count) = data
        return 0 unless total_count.positive?

        percent = (chronic_count.to_f / total_count * 100).round
        return percent if total_count > 1_000

        percent.round(-1)
      when 'race'
        # Collapse any where the count of the bucket is < 100 into the None
        data['None'] ||= Set.new
        data.each do |k, ids|
          next unless ids.count < 100

          data['None'] += ids
          data[k] = Set.new
        end
      else
        # Default case is simply to return a formatted number
        number_with_delimiter(data[key])
      end
    end

    private def under_threshold
      'Under 100'
    end
  end
end
