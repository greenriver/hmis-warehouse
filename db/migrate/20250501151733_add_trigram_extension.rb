# frozen_string_literal: true

class AddTrigramExtension < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
  end
end
