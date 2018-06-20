class AddReviewedByToReleaseForms < ActiveRecord::Migration
  def change
    add_reference :release_forms, :reviewed_by, index: true
    remove_column :release_forms, :supervisor_reviewed, :boolean
  end
end
