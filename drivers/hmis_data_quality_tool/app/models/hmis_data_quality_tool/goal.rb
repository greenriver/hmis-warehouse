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
  end
end
