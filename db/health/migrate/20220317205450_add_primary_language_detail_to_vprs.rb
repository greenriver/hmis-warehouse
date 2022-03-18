class AddPrimaryLanguageDetailToVprs < ActiveRecord::Migration[6.1]
  def change
    add_column :health_flexible_service_vprs, :primary_language_detail, :string
  end
end
