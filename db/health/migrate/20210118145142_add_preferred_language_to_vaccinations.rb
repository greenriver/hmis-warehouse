class AddPreferredLanguageToVaccinations < ActiveRecord::Migration[5.2]
  def change
    add_column :vaccinations, :preferred_language, :string, default: :en
  end
end
