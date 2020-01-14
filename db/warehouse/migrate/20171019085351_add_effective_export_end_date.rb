class AddEffectiveExportEndDate < ActiveRecord::Migration[4.2]
  def change
    add_column :Export, :effective_export_end_date, :date
  end
end
