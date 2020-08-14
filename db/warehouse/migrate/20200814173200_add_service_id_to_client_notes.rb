class AddServiceIdToClientNotes < ActiveRecord::Migration[5.2]
  def change
    add_reference :client_notes, :service
    add_reference :client_notes, :project
  end
end
