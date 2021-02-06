class CreateTwoFactorsTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :two_factors_tokens do |t|
      t.references :user, foreign_key: true
      t.string :guid
      t.string :name

      t.timestamps
    end
  end
end
