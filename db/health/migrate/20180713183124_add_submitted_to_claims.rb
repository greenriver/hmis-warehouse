class AddSubmittedToClaims < ActiveRecord::Migration[4.2]
  def change
    add_column :claims, :submitted_at, :datetime
  end
end
