class AddLanguageToHudReportAprClients < ActiveRecord::Migration[6.1]
  def change
    table = :hud_report_apr_clients
    add_column table, :translation_needed, :integer
    add_column table, :preferred_language, :integer
    add_column table, :preferred_language_different, :string
  end
end
