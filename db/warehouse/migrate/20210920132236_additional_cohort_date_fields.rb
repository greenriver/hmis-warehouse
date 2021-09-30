class AdditionalCohortDateFields < ActiveRecord::Migration[5.2]
  def change
    (11..30).to_a.each do |i|
      add_column :cohort_clients, "user_date_#{i}", :string
    end
  end
end
