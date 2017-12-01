module GrdaWarehouse::WarehouseReports
  class ReportDefinition < GrdaWarehouseBase

    has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::UserViewableEntity'

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      else
        joins(:user_viewable_entities)
      end
    end

  end
end
