class AddVerificationSource < ActiveRecord::Migration
  def change
    create_table :verification_source do |t|
      t.references :client
      t.string :disability_verification

      t.timestamps
    end
  end
end
