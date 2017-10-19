class AddEffectiveExportEndDate < ActiveRecord::Migration
  def change
    add_column :Export, :effective_export_end_date, :date
  end
end
