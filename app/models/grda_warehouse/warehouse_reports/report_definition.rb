###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class ReportDefinition < GrdaWarehouseBase

    has_many :group_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::GroupViewableEntity'

    scope :enabled, -> do
      where(enabled: true)
    end

    scope :viewable_by, -> (user) do
      return none unless user
      if user.can_view_all_reports?
        current_scope
      elsif user.can_view_assigned_reports?
        joins(:group_viewable_entities).
          merge(GrdaWarehouse::GroupViewableEntity.viewable_by(user))
      else
        none
      end
    end

    scope :assignable_by, -> (user) do
      return none unless user
      if user.can_view_all_reports?
        current_scope
      else
        none
      end
    end

    scope :ordered, -> do
      order(weight: :asc, name: :asc)
    end
  end
end
