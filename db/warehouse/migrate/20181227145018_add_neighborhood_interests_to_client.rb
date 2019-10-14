class AddNeighborhoodInterestsToClient < ActiveRecord::Migration
  def change
    add_column :Client, :neighborhood_interests, :jsonb, default:[], null: false
  end
end
