class AddExternalIdUniqIdx < ActiveRecord::Migration[6.1]
  def change
    # https://github.com/greenriver/hmis-warehouse/pull/2933/files#r1163372134
    # a source can only have one external_id for a given remote_credential
    add_index :external_ids, [:source_id, :source_type, :remote_credential_id], unique: true, name: 'external_ids_uniq_source_value'
  end
end
