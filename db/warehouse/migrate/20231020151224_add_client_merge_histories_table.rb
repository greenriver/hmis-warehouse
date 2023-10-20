class AddClientMergeHistoriesTable < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_client_merge_histories do |t|
      t.references :retained_client, null: true, foreign_key: { to_table: 'Client' }, index: true
      t.references :deleted_client, null: true, foreign_key: { to_table: 'Client' }
      t.references :client_merge_audit, null: false, foreign_key: { to_table: 'hmis_client_merge_audits' }, comment: 'Audit log for the merge that deleted the deleted_client'

      t.timestamps
    end
  end
end
