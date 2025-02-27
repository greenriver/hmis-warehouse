# frozen_string_literal: true

class AddLastUsedOnToImportOverrides < ActiveRecord::Migration[7.0]
  def change
    add_column :import_overrides, :last_used_on, :date
  end
end
