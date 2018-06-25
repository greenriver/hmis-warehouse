class AddHealthFileToReleaseForms < ActiveRecord::Migration
  def change
    add_reference :release_forms, :health_file, index: true, foreign_key: true
  end
end
