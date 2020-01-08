class AddNotNullConstraintsToAdHoc < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::AdHocDataSource.where(name: nil).update_all(name: 'Un-named')
    GrdaWarehouse::AdHocBatch.where(description: nil).update_all(description: 'Un-named')

    change_column_null :ad_hoc_data_sources, :name, false
    change_column_null :ad_hoc_batches, :description, false
  end
end
