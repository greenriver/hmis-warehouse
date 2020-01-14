class StoreVerificationDateInVerificationSources < ActiveRecord::Migration[4.2]
  def change
    add_column :verification_sources, :verified_at, :datetime
  end
end
