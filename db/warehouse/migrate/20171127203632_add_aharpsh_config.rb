class AddAharpshConfig < ActiveRecord::Migration
  def change
    add_column :configs, :ahar_psh_includes_rrh, :boolean, default: true
  end
end
