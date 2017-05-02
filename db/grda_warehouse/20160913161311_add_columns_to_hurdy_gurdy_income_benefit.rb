class AddColumnsToHurdyGurdyIncomeBenefit < ActiveRecord::Migration
  def change
    table = GrdaWarehouse::Hud::IncomeBenefit.table_name
    add_column table, 'IndianHealthServices', :integer
    add_column table, 'NoIndianHealthServicesReason', :integer
    add_column table, 'OtherInsurance', :integer
    add_column table, 'OtherInsuranceIdentify', :string, limit: 50
  end
end