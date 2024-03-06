class SupersetRole < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :superset_roles, :jsonb, default: []
  end
end
