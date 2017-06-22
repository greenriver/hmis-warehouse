class AddConnectionWithSoarToIncomeBenefits < ActiveRecord::Migration
  def change
    add_column :IncomeBenefits, :ConnectionWithSOAR, :integer
  end
end
