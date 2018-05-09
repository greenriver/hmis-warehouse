class AddConsentTypeToClientFiles < ActiveRecord::Migration
  def change
    add_column :files, :consent_type, :string
  end
end
