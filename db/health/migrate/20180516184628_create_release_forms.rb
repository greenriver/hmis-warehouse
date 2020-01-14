class CreateReleaseForms < ActiveRecord::Migration[4.2]
  def change
    create_table :release_forms do |t|
      t.belongs_to :patient, index: true
      t.belongs_to :user, index: true
      t.date :signature_on
      t.string :file_location
      t.boolean :supervisor_reviewed
    end
  end
end
