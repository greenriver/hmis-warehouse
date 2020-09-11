class AddIndexForImportAggregation < ActiveRecord::Migration[5.2]
  def change
    add_index :hmis_2020_aggregated_enrollments, [:PersonalID, :ProjectID, :data_source_id], name: :hmis_2020_agg_enrollments_p_id_p_id_ds_id
  end
end
