class AddPatientReferralReport < ActiveRecord::Migration
  REPORTS = {
    'Health' => [
      {
        url: 'warehouse_reports/health/patient_referrals',
        name: 'Patient Referrals',
        description: 'View and update batches of patient referrals by referral date.',
        limitable: false,
      },
    ],
  }


  def up
    REPORTS.each do |group, reports|
      reports.each do |report|
        GrdaWarehouse::WarehouseReports::ReportDefinition.create(
          report_group: group,
          url: report[:url],
          name: report[:name],
          description: report[:description],
          limitable: report[:limitable],
        )
      end
    end
  end

  def down
    REPORTS.each do |group, reports|
      reports.each do |report|
        GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: report[:url]).delete_all
      end
    end
  end
end
