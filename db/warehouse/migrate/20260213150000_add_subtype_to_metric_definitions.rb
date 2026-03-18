# frozen_string_literal: true

class AddSubtypeToMetricDefinitions < ActiveRecord::Migration[7.0]
  def change
    add_column :metric_definitions, :subtype, :string
  end
end
