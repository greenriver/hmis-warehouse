class SetModeOfContactForReleaseForms < ActiveRecord::Migration[6.1]
  def up
    Health::ReleaseForm.where(verbal_approval: true).update_all(mode_of_contact: :verbal)
    Health::ReleaseForm.where(verbal_approval: false).update_all(mode_of_contact: :in_person)
  end
end
