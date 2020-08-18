class AddYouthIntakeAgenciesArray < ActiveRecord::Migration[5.2]
  def change
    add_column :youth_intakes, :other_agency_involvements, :json, default: []
  end
end
