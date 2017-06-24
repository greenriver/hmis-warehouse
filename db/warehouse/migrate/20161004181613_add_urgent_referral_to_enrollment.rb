class AddUrgentReferralToEnrollment < ActiveRecord::Migration
  def change
    table = GrdaWarehouse::Hud::Enrollment.table_name
    add_column table, 'UrgentReferral', :integer
    add_column table, 'TimeToHousingLoss', :integer
    add_column table, 'ZeroIncome', :integer
    add_column table, 'AnnualPercentAMI', :integer
    add_column table, 'FinancialChange', :integer
    add_column table, 'HouseholdChange', :integer
    add_column table, 'EvictionHistory', :integer
    add_column table, 'SubsidyAtRisk', :integer
    add_column table, 'LiteralHomelessHistory', :integer
    add_column table, 'DisabledHoH', :integer
    add_column table, 'CriminalRecord', :integer
    add_column table, 'SexOffender', :integer
    add_column table, 'DependentUnder6', :integer
    add_column table, 'SingleParent', :integer
    add_column table, 'HH5Plus', :integer
    add_column table, 'IraqAfghanistan', :integer
    add_column table, 'FemVet', :integer
    add_column table, 'ThresholdScore', :integer
    add_column table, 'ERVisits', :integer
    add_column table, 'JailNights', :integer
    add_column table, 'HospitalNights', :integer
  end
end
