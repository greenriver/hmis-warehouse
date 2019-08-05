class AddDisabilityCuid < ActiveRecord::Migration
  def change
    add_column :bo_configs, :disability_verification_cuid, :string
    add_column :bo_configs, :disability_touch_point_id, :integer
    add_column :bo_configs, :disability_touch_point_question_id, :integer
  end
end
