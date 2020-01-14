class AddNeighborhoodInterestsToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :neighborhood_interests, :jsonb, default:[], null: false
  end
end
