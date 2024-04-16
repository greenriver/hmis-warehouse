class AddCohortColumnUserStrings < ActiveRecord::Migration[6.1]
  def change
    (9..30).each do |i|
      add_column :cohort_clients, "user_string_#{i}", :string
    end
  end
end
