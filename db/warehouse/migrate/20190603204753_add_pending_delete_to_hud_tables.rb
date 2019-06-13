class AddPendingDeleteToHudTables < ActiveRecord::Migration
  def change
    add_column :Affiliation, :pending_date_deleted, :datetime, default: nil
    add_column :Client, :pending_date_deleted, :datetime, default: nil
    add_column :Disabilities, :pending_date_deleted, :datetime, default: nil
    add_column :EmploymentEducation, :pending_date_deleted, :datetime, default: nil
    add_column :Enrollment, :pending_date_deleted, :datetime, default: nil
    add_column :EnrollmentCoC, :pending_date_deleted, :datetime, default: nil
    add_column :Exit, :pending_date_deleted, :datetime, default: nil
    add_column :Funder, :pending_date_deleted, :datetime, default: nil
    add_column :Geography, :pending_date_deleted, :datetime, default: nil
    add_column :HealthAndDV, :pending_date_deleted, :datetime, default: nil
    add_column :IncomeBenefits, :pending_date_deleted, :datetime, default: nil
    add_column :Inventory, :pending_date_deleted, :datetime, default: nil
    add_column :Organization, :pending_date_deleted, :datetime, default: nil
    add_column :Project, :pending_date_deleted, :datetime, default: nil
    add_column :ProjectCoC, :pending_date_deleted, :datetime, default: nil
    add_column :Services, :pending_date_deleted, :datetime, default: nil

    add_index :Affiliation, :pending_date_deleted
    add_index :Client, :pending_date_deleted
    add_index :Disabilities, :pending_date_deleted
    add_index :EmploymentEducation, :pending_date_deleted
    add_index :Enrollment, :pending_date_deleted
    add_index :EnrollmentCoC, :pending_date_deleted
    add_index :Exit, :pending_date_deleted
    add_index :Funder, :pending_date_deleted
    add_index :Geography, :pending_date_deleted
    add_index :HealthAndDV, :pending_date_deleted
    add_index :IncomeBenefits, :pending_date_deleted
    add_index :Inventory, :pending_date_deleted
    add_index :Organization, :pending_date_deleted
    add_index :Project, :pending_date_deleted
    add_index :ProjectCoC, :pending_date_deleted
    add_index :Services, :pending_date_deleted
  end
end
