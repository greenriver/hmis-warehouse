# provides validation for date ranges
module Filters
  class Initiative < DateRange
    include ArelHelper
    attribute :sub_population, Symbol, default: :all_clients
    attribute :comparison_start, Date, lazy: true, default: -> (r,_) { r.default_comparison_start }
    attribute :comparison_end, Date, lazy: true, default: -> (r,_) { r.default_comparison_end }
    attribute :initiative_name, String, default: nil
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []

    validates_presence_of :initiative_name, :start, :end, :comparison_start, :comparison_end

    validate do
      if start > self.end
        errors.add(:end, 'End date must follow start date.')
      end
      if comparison_start > self.comparison_end
        errors.add(:comparison_end, 'End date must follow start date.')
      end
      if project_ids.reject(&:blank?).blank? && project_group_ids.reject(&:blank?).blank?
        errors.add(:project_ids, 'At least one project or project group is required.')
      end 
    end

    def comparison_range
      self.comparison_start .. self.comparison_end
    end

    def comparison_first
      comparison_range.begin
    end

    def comparison_last
      comparison_range.end
    end

    def default_start
      self.end - 1.months
    end

    def default_end
      Date.today
    end

    def default_comparison_start
      self.start - 1.years
    end

    def default_comparison_end
      self.end - 1.years
    end

    def options_for_initiative
      options = {
        initiative_name: initiative_name,
        start: start,
        end: self.end,
        comparison_start: comparison_start,
        comparison_end: self.comparison_end,
        projects: effective_project_ids,
        sub_population: sub_population,
      }
    end

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      # if @effective_project_ids.empty?
      #   @effective_project_ids = all_project_ids
      # end
      return @effective_project_ids.uniq
    end

    def effective_project_ids_from_projects
      project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      GrdaWarehouse::ProjectGroup.joins(:projects).
        where(id: project_group_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end
  
    def all_project_ids
      GrdaWarehouse::Hud::Project.pluck(:id)
    end
  end
end
