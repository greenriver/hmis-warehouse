class AddTemporaryTokenToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :generate_history_pdf, :boolean, default: false
  end
end
