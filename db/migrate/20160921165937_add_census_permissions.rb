class AddCensusPermissions < ActiveRecord::Migration[4.2]
  def up
    admin = Role.where(name: 'admin').first_or_create
    dnd = Role.where(name: 'dnd_staff').first_or_create
    admin.update({ can_view_census_details: true })
    dnd.update({ can_view_census_details: true })
  end
end
