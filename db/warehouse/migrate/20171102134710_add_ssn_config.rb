class AddSsnConfig < ActiveRecord::Migration
  def change
    add_column :configs, :show_partial_ssn_in_window_search_results, :boolean, default: :false
    add_column :configs, :url_of_blank_consent_form, :string
  end
end
