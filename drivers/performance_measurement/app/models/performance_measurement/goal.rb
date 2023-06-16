###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Goal < GrdaWarehouseBase
    acts_as_paranoid
    has_many :pit_counts

    scope :default, -> do
      where(coc_code: :default)
    end

    scope :coc, -> do
      ordered.where.not(coc_code: :default)
    end

    scope :ordered, -> do
      order(active: :desc, coc_code: :asc)
    end

    scope :active, -> do
      where(active: true)
    end

    def self.for_coc(coc_code)
      goal = where(coc_code: coc_code).active.first
      return goal if goal

      default_goal
    end

    def self.default_goal
      default.first_or_create
    end

    def self.ensure_default
      default_goal
    end

    def self.include_project_options?
      ! default_goal.always_run_for_coc
    end

    def self.default_first
      goals = [default_goal]
      goals += coc.to_a
      goals.group_by(&:coc_name)
    end

    def duplicate!
      new_goal = dup
      new_goal.active = true
      self.class.transaction do
        update(active: false)
        new_goal.save!
        pit_counts.each do |p|
          new_count = p.dup
          new_count.goal_id = new_goal.id
          new_count.save!
        end
      end
      new_goal
    end

    def enforce_activation!
      return unless active?

      self.class.where(coc_code: coc_code).
        where.not(id: id).
        update_all(active: false)
    end

    def available_cocs(user)
      ::Filters::HudFilterBase.new(user_id: user.id).
        coc_code_options_for_select(user: user)
    end

    def coc_name
      name = ::HudUtility.coc_name(coc_code)
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
