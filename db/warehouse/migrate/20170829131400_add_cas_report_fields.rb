class AddCasReportFields < ActiveRecord::Migration
  def change
    add_column :cas_reports, :shelter_agency_contacts, :json
    add_column :cas_reports, :hsa_contacts, :json
    add_column :cas_reports, :ssp_contacts, :json
    add_column :cas_reports, :admin_contacts, :json
    add_column :cas_reports, :clent_contacts, :json
    add_column :cas_reports, :hsp_contacts, :json        
  end
end
