class AddDeletedDatToCeClients < ActiveRecord::Migration[6.1]
  def change
    add_column :ce_performance_clients, :ce_apr_client_id, :integer
    add_column :ce_performance_clients, :dob, :date
    add_column :ce_performance_clients, :move_in_date, :date
    add_column :ce_performance_clients, :period, :string
    add_column :ce_performance_clients, :household_type, :string
    add_column :ce_performance_clients, :days_before_assessment, :integer
    add_column :ce_performance_clients, :days_on_list, :integer
    add_column :ce_performance_clients, :days_in_project, :integer
    add_column :ce_performance_clients, :days_between_referral_and_housing, :integer
    add_column :ce_performance_clients, :q5a_b1, :boolean, default: false
    add_column :ce_performance_clients, :deleted_at, :datetime

    add_column :ce_performance_results, :type, :string
    add_column :ce_performance_results, :period, :string
    add_column :ce_performance_results, :deleted_at, :datetime

    create_table :ce_performance_ce_aprs do |t|
      t.belongs_to :report, null: false
      t.belongs_to :ce_apr, null: false
      t.date :start_date
      t.date :end_date
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
