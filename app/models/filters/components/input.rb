# sanitized filter input
module Filters::Components
  class Input
    attr_reader :filters, :user, :age_ranges
    def initialize(filters:, user:)
      @filters = filters
      @user = user
    end

    def project_ids
      GrdaWarehouse::Hud::Project
        .viewable_by(user, permission: :can_view_assigned_reports))
        .where(id: filter.project_ids.compact.uniq)
        .order(:id)
        .pluck(:id)
    end

    def project_group_ids
      GrdaWarehouse::Hud::ProjectGroup
        .viewable_by(user, permission: :can_view_assigned_reports))
        .where(id: filter.project_group_ids.compact.uniq)
        .order(:id)
        .pluck(:id)
    end

    def age_ranges
      filter.available_age_ranges.values & filter.age_ranges
    end
  end
end
