class TalentConfigurationFlags < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :default_lms_email_to_warehouse_email, :boolean
    add_column :talentlms_configs, :allow_automatic_redirect_to_course, :boolean
  end
end
