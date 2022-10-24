class AddParticipationSignatureToReleaseForm < ActiveRecord::Migration[6.1]
  def change
    add_column :release_forms, :participation_signature_on, :date
  end
end
