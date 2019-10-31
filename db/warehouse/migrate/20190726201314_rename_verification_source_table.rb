class RenameVerificationSourceTable < ActiveRecord::Migration[4.2]
  def change
    rename_table :verification_source, :verification_sources
  end
end
