class AddDisplayHookToCustomDataElementDef < ActiveRecord::Migration[6.1]
  def change
    add_column :CustomDataElementDefinitions, :show_in_summary, :boolean, default: false, null: false, comment: 'Whether to show this custom field in summary views such as in a table row when viewing a Service/CLS/Note'
  end
end
