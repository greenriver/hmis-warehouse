class AddIndexHmisAssessments < ActiveRecord::Migration[6.1]
  def change
    add_index :hmis_assessments, [:active, :exclude_from_window, :confidential], name: :hmis_a_act_exl_con
    add_index :hmis_assessments, :name
  end
end
