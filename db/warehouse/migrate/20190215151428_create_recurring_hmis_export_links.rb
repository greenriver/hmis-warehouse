class CreateRecurringHmisExportLinks < ActiveRecord::Migration
  def change
    create_table :recurring_hmis_export_links do |t|
      t.references :hmis_export
      t.references :recurring_hmis_export
      t.date :exported_at
    end

    remove_column :recurring_hmis_exports, :hmis_export_id
  end
end
