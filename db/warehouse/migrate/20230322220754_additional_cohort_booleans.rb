class AdditionalCohortBooleans < ActiveRecord::Migration[6.1]
  def change
    (31..49).each do |i|
      add_column :cohort_clients, "user_boolean_#{i}", :boolean
    end
  end
end
