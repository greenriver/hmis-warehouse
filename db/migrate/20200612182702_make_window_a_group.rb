class MakeWindowAGroup < ActiveRecord::Migration[5.2]
  def up
    group = AccessGroup.general.where(name: 'Window').first_or_create

    GrdaWarehouse::DataSource.where(visible_in_window: true).find_each do |ds|
      group.add_viewable(ds)
    end

    User.can_view_client_window.find_each do |user|
      group.add(user)
    end
  end
  def down
    group = AccessGroup.general.where(name: 'Window').first
    group.destroy if group.present?
  end
end
