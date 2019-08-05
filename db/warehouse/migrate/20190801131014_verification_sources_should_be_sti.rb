class VerificationSourcesShouldBeSti < ActiveRecord::Migration
  def change
    add_column :verification_sources, :type, :string
    rename_column :verification_sources, :disability_verification, :location
  end
end
