class AddUserIdToAdHoc < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::AdHocDataSource.find_each do |ds|
      id = ds.ad_hoc_batches&.first&.user_id
      next unless id

      ds.update(user_id: id)
    end
  end
end
