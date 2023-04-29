class AddExternalIdNamespace < ActiveRecord::Migration[6.1]
  # ensure all IDs are unique in a namespace.
  # https://www.pivotaltracker.com/story/show/185000178/comments/236605163
  def change
    add_column :external_ids, :namespace, :string, null: true
    # The condition here allows two for two clients to share the same MCI ID
    # https://github.com/greenriver/hmis-warehouse/pull/2933/files#r1164091887
    add_index :external_ids,
              [:source_type, :namespace, :value],
              unique: true,
              name: 'uidx_external_id_ns_value',
              where: "(namespace <> 'ac_hmis_mci')"
  end
end
