class AddHealthFileToReleaseForms < ActiveRecord::Migration[4.2]
  def change
    add_reference :release_forms, :health_file, index: true, foreign_key: true
  end
end
