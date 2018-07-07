class SetDefaultAcOs < ActiveRecord::Migration
  def up
    acos.each do |short_name, name|
      Health::AccountableCareOrganization.where(name: name, short_name: short_name).first_or_create
    end
  end

  def acos
    {
      'BMC-BACO' => 'Boston Accountable Care Organization in partnership with BMC HealthNet Plan',
      'BMC-Mercy' => 'Mercy Medical Center in partnership with BMC HealthNet Plan', 
      'BMC-Signature' => 'Signature Healthcare in partnership with BMC HealthNet Plan',
      'BMC-Southcoast' => 'Southcoast Health in partnership with BMC HealthNet Plan',
      'FLN-Berkshire' => 'Health Collaborative of the Berkshires in partnership with Fallon Health',
      'FLN-Reliant' => 'Reliant Medical Group in partnership with Fallon Health',
      'FLN-Wellforce' => 'Wellforce in partnership with Fallon Health',
      'HNE-Baystate' => 'Baystate Health Care Alliance in partnership with Health New England',
      'NHP-MVACO' => 'Merrimack Valley ACO in partnership with Neighborhood Health Plan',
      'Tufts-Atrius' => 'Atrius Health in partnership with Tufts Health Public Plans (THPP)',
      'Tufts-BIDCO' => 'Beth Israel Deaconess Care Organization (BIDCO) in partnership with Tufts Health Public Plans (THPP)',
      'Tufts-CHA' => 'Cambridge Health Alliance (CHA) in partnership with Tufts Health Public Plans (THPP)',
      'Tufts-CHICO' => 'Boston Children\'s Health ACO in partnership with Tufts Health Public Plans (THPP)',
      'CCC' => 'Community Care Cooperative (C3)',
      'PHACO' => 'Partners Care Connect',
      'Steward' => 'Steward Medicaid Care Network',
      'Lahey' => 'Lahey Clinical Performance Network (LCPN)',    
    }
  end
end
