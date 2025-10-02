# frozen_string_literal: true

class AddDjKedaMetrics < ActiveRecord::Migration[7.1]
  def change
    create_view 'puma_scaling_login_demand'
  end
end
