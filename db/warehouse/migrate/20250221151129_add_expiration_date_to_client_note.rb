# frozen_string_literal: false

class AddExpirationDateToClientNote < ActiveRecord::Migration[7.0]
  def change
    add_column :client_notes, :expiration_date, :date
  end
end
