class RenameVerificationSourceTable < ActiveRecord::Migration
  def change
    rename_table :verification_source, :verification_sources
  end
end
