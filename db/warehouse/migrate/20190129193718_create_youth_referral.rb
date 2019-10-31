class CreateYouthReferral < ActiveRecord::Migration[4.2]
  def change
    create_table :youth_referrals do |t|
      t.references :client
      t.references :user
      t.date :referred_on
      t.string :referred_to
      
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
