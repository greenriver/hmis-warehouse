# frozen_string_literal: true

class RemoveRefuseImportsWithErrors < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :data_sources, :refuse_imports_with_errors }
  end
end
