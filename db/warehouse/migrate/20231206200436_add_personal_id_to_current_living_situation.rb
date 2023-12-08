class AddPersonalIdToCurrentLivingSituation < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_current_living_situations, :personal_id, :string
  end
end
