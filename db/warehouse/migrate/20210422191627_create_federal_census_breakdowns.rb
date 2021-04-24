class CreateFederalCensusBreakdowns < ActiveRecord::Migration[5.2]
  def change
    create_table :federal_census_breakdowns do |t|
      t.date :accurate_on, comment: 'Most recent census date'
      t.string :type
      t.string :geography_level, comment: 'State, zip, CoC (or maybe 010, 040, 050)'
      t.string :geography, comment: 'MA, 02101, MA-500'
      t.string :group, comment: 'All, age range, gender, this represents the sub-poplation you want to pull'
      t.string :measure, comment: 'Detail of race, age, etc. (Asian, 50-59...)'
      t.integer :value, comment: 'count of population'
    end

    add_index(:federal_census_breakdowns, [:accurate_on, :geography, :geography_level, :measure], name: :idx_fed_census_acc_on_geo_measure)
  end
end
