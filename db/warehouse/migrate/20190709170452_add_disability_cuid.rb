class AddDisabilityCuid < ActiveRecord::Migration[4.2]
  def change
    add_column :bo_configs, :disability_verification_cuid, :string
    add_column :bo_configs, :disability_touch_point_id, :integer
    add_column :bo_configs, :disability_touch_point_question_id, :integer
  end
end
