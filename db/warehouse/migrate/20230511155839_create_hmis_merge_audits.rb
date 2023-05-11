class CreateHmisMergeAudits < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_client_merge_audits do |t|
      t.jsonb :pre_merge_state, null: false
      t.bigint :actor_id, null: false
      t.timestamp :merged_at, null: false

      t.timestamps
    end
  end
end
