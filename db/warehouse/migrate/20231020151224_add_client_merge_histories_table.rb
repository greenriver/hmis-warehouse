class AddClientMergeHistoriesTable < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_client_merge_histories do |t|
      t.references :retained_client, null: false, index: true
      t.references :deleted_client, null: false
      t.references :client_merge_audit, null: false, comment: 'Audit log for the merge that deleted the deleted_client'

      t.timestamps
    end
  end
end
