###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Goal < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_goals'
    acts_as_paranoid

    def self.known_params
      columns = [:coc_code]
      segment_numbers.each do |num|
        columns << "segment_#{num}_name".to_sym
        columns << "segment_#{num}_color".to_sym
        columns << "segment_#{num}_low".to_sym
        columns << "segment_#{num}_high".to_sym
      end
      columns
    end

    def self.segment_numbers
      (0..9)
    end

    scope :default, -> do
      where(coc_code: :default)
    end

    scope :coc, -> do
      where.not(coc_code: :default)
    end

    def self.for_coc(coc_code)
      goal = where(coc_code: coc_code).first
      return goal if goal

      default_goal
    end

    def self.default_goal
      default.first_or_create
    end

    def self.ensure_default
      default_goal
    end

    def self.default_first
      goals = [default_goal]
      goals += coc.to_a
      goals
    end

    def available_cocs
      ::HUD.cocs_in_state(ENV['RELEVANT_COC_STATE']).map do |code, name|
        [
          "#{name} (#{code})",
          code,
        ]
      end
    end

    def coc_name
      name = ::HUD.coc_name(coc_code)
      return "#{name} (#{coc_code})" unless name == coc_code

      coc_code
    end

    def default?
      coc_code.to_s == 'default'
    end

    def deleteable?
      ! default?
    end

    def active_segments
      @active_segments ||= {}.tap do |segments|
        self.class.segment_numbers.each do |num|
          low = send("segment_#{num}_low")
          high = send("segment_#{num}_high")
          next if low.blank? && high.blank?

          segments[num] = range(low, high)
        end
      end
    end

    def range(low, high)
      return nil unless low.present? || high.present?

      (low || 0)..(high || 100)
    end

    private def segment_number_for(value)
      return unless active_segments.present?

      # segment will be an array of [num, range], or nil
      segment = active_segments.detect { |_, range| range.cover?(value.to_i) }
      segment&.first
    end

    def color_for(value)
      return unless active_segments.present?

      segment_number = segment_number_for(value.to_i)
      return unless segment_number.present?

      send("segment_#{segment_number}_color")
    end

    def name_for(value)
      return unless active_segments.present?

      segment_number = segment_number_for(value.to_i)
      return unless segment_number.present?

      send("segment_#{segment_number}_name")
    end

    def overall_percent(values)
      count = values.count
      return 0 if values.count.zero?

      sum = values.sum
      return 0 if sum.zero?

      (sum.to_f / count).round(1)
    end
  end
end
