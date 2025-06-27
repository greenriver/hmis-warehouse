# frozen_string_literal: true

class CreateClientChangeMarkers < ActiveRecord::Migration[7.1]
  def change
    create_table 'client_change_markers' do |t|
      t.references :client, null: false, index: { unique: true }
      t.integer :current_version, null: false
      t.integer :processed_version, null: false, default: 0
    end
  end
end
