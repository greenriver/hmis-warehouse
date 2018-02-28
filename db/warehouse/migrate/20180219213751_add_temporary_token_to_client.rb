class AddTemporaryTokenToClient < ActiveRecord::Migration
  def change
    add_column :Client, :generate_history_pdf, :boolean, default: false
  end
end
