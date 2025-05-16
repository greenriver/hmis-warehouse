class UpdateAggregatedEnrollmentForFy2026 < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_aggregated_enrollments, :MentalHealthConsultation, :integer
  end
end
