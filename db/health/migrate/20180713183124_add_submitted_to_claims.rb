class AddSubmittedToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :submitted_at, :datetime
  end
end
