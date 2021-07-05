class SetDefaultForCanViewProjectRelatedFilters < ActiveRecord::Migration[5.2]
  def up
    # Since this is a new permission, default it for anyone who can currently see reports of any variety
    Role.where(can_view_all_reports: true).update_all(can_view_project_related_filters: true)
    Role.where(can_view_assigned_reports: true).update_all(can_view_project_related_filters: true)
  end
end
