# frozen_string_literal: true

class AddCalculationExpressionToCustomDataElementDefinitions < ActiveRecord::Migration[7.2]
  def change
    add_column :CustomDataElementDefinitions, :calculation_expression, :text
  end
end

# rails db:migrate:up:warehouse VERSION=20260421182915
# rails db:migrate:down:warehouse VERSION=20260421182915
