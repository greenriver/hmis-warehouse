class VerificationSourcesShouldBeSti < ActiveRecord::Migration[4.2]
  def change
    add_column :verification_sources, :type, :string
    rename_column :verification_sources, :disability_verification, :location
  end
end
