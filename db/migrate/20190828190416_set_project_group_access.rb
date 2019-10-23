class SetProjectGroupAccess < ActiveRecord::Migration
  def up
    # user_ids = User.joins(:roles).merge(Role.where(can_edit_project_groups: true)).distinct.pluck(:id)
    # return unless user_ids

    # GrdaWarehouse::ProjectGroup.find_each do |pg|
    #   user_ids.each do |id|
    #     pg.user_viewable_entities.where(user_id: id).first_or_create
    #   end
    # end
  end
end
