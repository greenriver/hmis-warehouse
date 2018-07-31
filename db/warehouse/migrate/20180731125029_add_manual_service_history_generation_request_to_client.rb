class AddManualServiceHistoryGenerationRequestToClient < ActiveRecord::Migration
  def change
    add_column :Client, :generate_manual_history_pdf, :boolean, default: false, null: false
  end
end
