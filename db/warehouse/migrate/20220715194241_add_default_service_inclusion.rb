class AddDefaultServiceInclusion < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :require_service_for_reporting_default, :boolean, null: false, default: true
  end
end
