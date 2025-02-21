class AddExpirationDateToClientNote < ActiveRecord::Migration[7.0]
  def change
    add_column :client_notes, :expiration_date, :datetime
  end
end
