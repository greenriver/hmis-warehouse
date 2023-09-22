class SetViewPermissionForWindowRequiresRoi < ActiveRecord::Migration[6.1]
  def up
    return unless ::GrdaWarehouse::Config.get(:window_access_requires_release)

    window = Collection.system_collection(:window_data_sources)
    AccessControl.where(collection_id: window.id).each do |ac|
      if ac.role.can_view_clients
        ac.role.update(can_view_clients: false, can_view_client_enrollments_with_roi: true)
      end
    end
  end
end
