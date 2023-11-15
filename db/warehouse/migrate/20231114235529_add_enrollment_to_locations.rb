class AddEnrollmentToLocations < ActiveRecord::Migration[6.1]
  def change
    # Run the following manually after this is deployed
    # ClientLocationHistory::Location.find_each do |clh|
    #   source = clh.source
    #   id = if source.is_a?(GrdaWarehouse::Hud::Enrollment)
    #     source.id
    #   else
    #     source.enrollment_id
    #   end
    #   clh.update(enrollment_id: id)
    # end

    add_column :clh_locations, :enrollment_id, :bigint, index: true
  end
end
