class Add2022LivingSituationColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :Exit, :Destination2022, :integer
    add_column :Enrollment, :LivingSituation2022, :integer
    add_column :CurrentLivingSituation, :CurrentLivingSituation2022, :integer
  end
end
