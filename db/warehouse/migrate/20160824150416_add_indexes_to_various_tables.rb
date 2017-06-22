class AddIndexesToVariousTables < ActiveRecord::Migration
  def change
    add_index 'Disabilities', 'PersonalID'
    add_index 'EmploymentEducation', 'PersonalID'
    add_index 'Enrollment', 'PersonalID'
    add_index 'Exit', 'PersonalID'
    add_index 'HealthAndDV', 'PersonalID'
    add_index 'IncomeBenefits', 'PersonalID'
    add_index 'Services', 'PersonalID'
    add_index :warehouse_clients, :destination_id
  end
end
