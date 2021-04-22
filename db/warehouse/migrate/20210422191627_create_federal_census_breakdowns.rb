class CreateFederalCensusBreakdowns < ActiveRecord::Migration[5.2]
  def change
    create_table :federal_census_breakdowns do |t|
      t.date :accurate_on
      t.string :type
      t.string :identifier
      t.string :measure
      t.integer :value
    end
  end
end
