class AddVerificationSource < ActiveRecord::Migration[4.2]
  def change
    create_table :verification_source do |t|
      t.references :client
      t.string :disability_verification

      t.timestamps
    end
  end
end
