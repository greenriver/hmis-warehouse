class AddEnrollmentToLocations < ActiveRecord::Migration[6.1]
  def change
    # Run the following manually after this is deployed
    # ClientLocationHistory::Location.find_each { |clh| clh.update(enrollment_id: clh.source&.enrollment_id) }
    add_column :clh_locations, :enrollment_id, :integer, index: true
  end
end
