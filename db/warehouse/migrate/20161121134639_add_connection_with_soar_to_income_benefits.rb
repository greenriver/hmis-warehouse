class AddConnectionWithSoarToIncomeBenefits < ActiveRecord::Migration[4.2]
  def change
    add_column :IncomeBenefits, :ConnectionWithSOAR, :integer
  end
end
