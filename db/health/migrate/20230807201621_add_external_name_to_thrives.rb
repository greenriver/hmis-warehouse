# frozen_string_literal: true

class AddExternalNameToThrives < ActiveRecord::Migration[6.1]
  def change
    add_column :thrive_assessments, :external_name, :string
  end
end
