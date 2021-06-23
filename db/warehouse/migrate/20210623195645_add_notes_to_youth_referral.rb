class AddNotesToYouthReferral < ActiveRecord::Migration[5.2]
  def change
    add_column :youth_referrals, :notes, :string
  end
end
