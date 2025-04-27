# frozen_string_literal: true

class AddSearchVectorToUsers < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
      add_index :users, :first_name, using: :gin, opclass: :gin_trgm_ops
      add_index :users, :last_name, using: :gin, opclass: :gin_trgm_ops
      add_index :users, :email, using: :gin, opclass: :gin_trgm_ops
    end
  end

  def down
    safety_assured do
      remove_index :users, :first_name
      remove_index :users, :last_name
      remove_index :users, :email
    end
  end
end
