class AddFederalCensusColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :federal_census_breakdowns, :geo_id, :string
    add_column :federal_census_breakdowns, :race, :string
    add_column :federal_census_breakdowns, :gender, :string
    add_column :federal_census_breakdowns, :age_min, :integer
    add_column :federal_census_breakdowns, :age_max, :integer
    add_column :federal_census_breakdowns, :source, :string, comment: 'Source of data'
    add_column :federal_census_breakdowns, :census_variable_name, :string, comment: 'For debugging, variable name used in source'
    remove_column :federal_census_breakdowns, :group, :string
  end
end
