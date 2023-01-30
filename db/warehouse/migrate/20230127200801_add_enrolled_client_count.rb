class AddEnrolledClientCount < ActiveRecord::Migration[6.1]
  def change
    add_column :ma_monthly_performance_enrollments, :first_name, :string
    add_column :ma_monthly_performance_enrollments, :last_name, :string
    add_column :ma_monthly_performance_projects, :enrolled_client_count, :integer
  end
end
