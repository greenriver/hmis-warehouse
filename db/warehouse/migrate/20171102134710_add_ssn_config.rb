class AddSSNConfig < ActiveRecord::Migration
  # We added an inflector for SSN, noted here in case it breaks the class name
  def change
    add_column :configs, :show_partial_ssn_in_window_search_results, :boolean, default: :false
    add_column :configs, :url_of_blank_consent_form, :string
  end
end
