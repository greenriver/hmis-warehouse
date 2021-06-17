class AddMoreUserCohortColumns < ActiveRecord::Migration[5.2]
  def change
    (11..30).to_a.each do |i|
      add_column :cohort_clients, "user_select_#{i}", :string
    end
    (16..30).to_a.each do |i|
      add_column :cohort_clients, "user_boolean_#{i}", :boolean
    end
  end
end
