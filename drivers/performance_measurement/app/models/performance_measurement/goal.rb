###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Goal < GrdaWarehouseBase
    acts_as_paranoid

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
