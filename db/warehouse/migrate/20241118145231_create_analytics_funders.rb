# frozen_string_literal: true

class CreateAnalyticsFunders < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.funders'
  end
end
