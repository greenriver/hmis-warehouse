# frozen_string_literal: true

class AddRelevantStateToSiteConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :relevant_state_codes, :string, default: ENV['RELEVANT_COC_STATE'] || 'MA', null: false
  end
end
