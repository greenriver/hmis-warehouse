class AddIdsToHudTables < ActiveRecord::Migration
  def change
    add_column 'Client', :id, :primary_key
    add_column 'Affiliation', :id, :primary_key
    add_column 'Disabilities', :id, :primary_key
    add_column 'EmploymentEducation', :id, :primary_key
    add_column 'Enrollment', :id, :primary_key
    add_column 'EnrollmentCoC', :id, :primary_key
    add_column 'Exit', :id, :primary_key
    add_column 'Export', :id, :primary_key
    add_column 'Funder', :id, :primary_key
    add_column 'HealthAndDV', :id, :primary_key
    add_column 'IncomeBenefits', :id, :primary_key
    add_column 'Inventory', :id, :primary_key
    add_column 'Organization', :id, :primary_key
    add_column 'Project', :id, :primary_key
    add_column 'ProjectCoC', :id, :primary_key
    add_column 'Services', :id, :primary_key
    add_column 'Site', :id, :primary_key
  end
end
