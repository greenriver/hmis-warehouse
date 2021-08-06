class AddSyntheticToHudAssessments < ActiveRecord::Migration[5.2]
  def change
    add_column :Assessment, :synthetic, :boolean, default: false
  end
end
