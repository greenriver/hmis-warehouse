class AddMarijuanaAnswerToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :marijuana_answer, :integer
    add_column :vispdats, :incarcerated_before_18_answer, :integer
    add_column :vispdats, :homeless_due_to_ran_away_answer, :integer
    add_column :vispdats, :homeless_due_to_religions_beliefs_answer, :integer
    add_column :vispdats, :homeless_due_to_family_answer, :integer
    add_column :vispdats, :homeless_due_to_gender_identity_answer, :integer
    add_column :vispdats, :violence_between_family_members_answer, :integer
  end
end
