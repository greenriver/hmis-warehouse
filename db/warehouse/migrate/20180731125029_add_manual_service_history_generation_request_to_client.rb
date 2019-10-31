class AddManualServiceHistoryGenerationRequestToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :generate_manual_history_pdf, :boolean, default: false, null: false
  end
end
