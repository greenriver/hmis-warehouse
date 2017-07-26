class CreateAdminConfig < ActiveRecord::Migration
  def change
    create_table :configs do |t|
      t.boolean :project_type_override, default: true, null: false
      t.boolean :eto_api_available, default: false, null: false
      t.string :cas_available_method, default: 'cas_flag', null: false
      t.boolean :healthcare_available, default: false, null: false
      t.json :site_coc_codes
    end
  end
end
