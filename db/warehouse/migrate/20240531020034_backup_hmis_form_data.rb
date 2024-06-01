class BackupHmisFormData < ActiveRecord::Migration[7.0]
  # create backup before destructive a update operation for link ids. Drop these columns if everything goes well
  def change
    add_column :hmis_form_definitions, :backup_definition, :jsonb
    add_column :hmis_form_processors, :backup_values, :jsonb

    reversible do |dir|
      dir.up do
        safety_assured do
          execute %(UPDATE hmis_form_definitions SET backup_definition = definition)
          execute %(UPDATE hmis_form_processors SET backup_values = values)
        end
      end
    end
  end
end
