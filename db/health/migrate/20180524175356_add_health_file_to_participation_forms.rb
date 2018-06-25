class AddHealthFileToParticipationForms < ActiveRecord::Migration
  def change
    add_reference :participation_forms, :health_file, index: true, foreign_key: true
  end
end
