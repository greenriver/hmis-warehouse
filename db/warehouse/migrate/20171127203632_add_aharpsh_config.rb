class AddAharpshConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :ahar_psh_includes_rrh, :boolean, default: true
  end
end
