class AddTranslationPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    admin = Role.where(name: 'admin').first
    dnd = Role.where(name: 'dnd_staff').first
    admin.update({can_edit_translations: true})
    dnd.update({can_edit_translations: true})
  end
  
  def down
    remove_column :roles, :can_edit_translations, :boolean
  end
end
