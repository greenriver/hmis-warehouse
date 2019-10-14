class StoreVerificationDateInVerificationSources < ActiveRecord::Migration
  def change
    add_column :verification_sources, :verified_at, :datetime
  end
end
