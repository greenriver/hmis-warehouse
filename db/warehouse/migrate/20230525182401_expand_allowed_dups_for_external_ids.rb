class ExpandAllowedDupsForExternalIds < ActiveRecord::Migration[6.1]
  INDEX_NAME = 'uidx_external_id_ns_value'

  def change
    remove_index :external_ids,
              [:source_type, :namespace, :value],
              unique: true,
              name: INDEX_NAME

    safety_assured do
      add_index :external_ids,
                [:source_type, :namespace, :value],
                unique: true,
                name: INDEX_NAME,
                where: "namespace not in ('ac_hmis_mci', 'ac_hmis_mci_unique_id')"
    end
  end

  def down
    remove_index :external_ids,
              [:source_type, :namespace, :value],
              unique: true,
              name: INDEX_NAME

    safety_assured do
      add_index :external_ids,
                [:source_type, :namespace, :value],
                unique: true,
                name: 'uidx_external_id_ns_value',
                where: "(namespace <> 'ac_hmis_mci')"
    end
  end
end
