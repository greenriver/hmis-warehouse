class AddValuesFormProcessor < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_form_processors, :wip_hud_values, :jsonb, null: true
  end
end
