###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Goal < ::GrdaWarehouseBase
    self.table_name = 'hmis_dqt_goals'
    acts_as_paranoid

    def self.known_params
      columns = [
        :coc_code,
        :entry_date_entered_length,
        :exit_date_entered_length,
        :expose_ch_calculations,
        :show_annual_assessments,
      ]
      columns += stay_length_categories
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
      where(coc_code: 'Un-Set')
    end

    scope :coc, -> do
      where.not(coc_code: 'Un-Set')
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
      ::HudUtility.cocs_in_state(ENV['RELEVANT_COC_STATE']).map do |code, name|
        [
          "#{name} (#{code})",
          code,
        ]
      end
    end

    def coc_name
      name = ::HudUtility.coc_name(coc_code)
      return "#{name} (#{coc_code})" unless name == coc_code

      coc_code
    end

    def default?
      coc_code.to_s == 'Un-Set'
    end

    def deleteable?
      ! default?
    end

    def active?
      active_segments.present?
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
      return unless active?

      # segment will be an array of [num, range], or nil
      segment = active_segments.detect { |_, range| range.cover?(value.to_i) }
      segment&.first
    end

    def color_for(value)
      return unless active?

      segment_number = segment_number_for(value.to_i)
      return unless segment_number.present?

      send("segment_#{segment_number}_color")
    end

    def name_for(value)
      return unless active?

      segment_number = segment_number_for(value.to_i)
      return unless segment_number.present?

      send("segment_#{segment_number}_name")
    end

    def self.stay_length_options
      {
        '90 Days' => 90,
        '180 Days' => 180,
        '365 Days' => 365,
      }
    end

    def self.stay_length_categories
      [
        :es_stay_length,
        :es_missed_exit_length,
        :so_missed_exit_length,
        :ph_missed_exit_length,
      ].freeze
    end

    def self.timeliness_categories
      {
        'Disabled' => -1,
        'Same day' => 0,
        '3 days or less' => 3,
        '6 days or less' => 6,
        '10 days or less' => 10,
        '11 or more days' => 10_000,
      }
    end

    def stay_lengths
      @stay_lengths ||= [].tap do |sl|
        self.class.stay_length_categories.each do |cat|
          value = send(cat)
          sl << [cat, value] if value.present?
        end
      end
    end
  end
end
