class AddRelationshipToHoHToAnsdEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :ansd_enrollments, :relationship_to_hoh, :integer
  end
end
