module GrdaWarehouse::WarehouseReports
  class ReportDefinition < GrdaWarehouseBase

    has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::UserViewableEntity'

    scope :viewable_by, -> (user) do
      if user.can_view_all_reports?
        current_scope
      elsif user.can_view_assigned_reports?
        joins(:user_viewable_entities).where(user_viewable_entities: {user_id: user.id})
      else
        none
      end
    end

    scope :ordered, -> do
      order(weight: :asc, name: :asc)
    end
  end
end
