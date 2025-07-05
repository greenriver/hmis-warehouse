# frozen_string_literal: true

class CreateClientChangeMarkers < ActiveRecord::Migration[7.1]
  def change
    create_table 'hmis_ce_change_markers' do |t|
      t.references :trackable, null: false, polymorphic: true, index: { unique: true }
      t.integer :current_version, null: false
      t.integer :processed_version, null: false, default: 0
    end
  end
end
