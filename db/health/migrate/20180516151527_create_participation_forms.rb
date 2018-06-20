class CreateParticipationForms < ActiveRecord::Migration
  def change
    create_table :participation_forms do |t|
      t.belongs_to :patient, index: true
      t.date :signature_on
      t.belongs_to :case_manager, index: true
      t.belongs_to :reviewed_by, index: true
      t.string :location
    end
  end
end
