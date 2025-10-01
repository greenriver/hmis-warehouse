# frozen_string_literal: true

class AddDjKedaMetrics < ActiveRecord::Migration[7.1]
  def change
    create_view 'puma_keda_metrics'
  end
end
