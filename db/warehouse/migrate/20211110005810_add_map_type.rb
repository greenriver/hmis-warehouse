class AddMapType < ActiveRecord::Migration[5.2]
  def change
    add_column :public_report_settings, :map_type, :string, null: false, default: :coc
  end
end
