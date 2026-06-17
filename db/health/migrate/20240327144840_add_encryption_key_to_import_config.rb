###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddEncryptionKeyToImportConfig < ActiveRecord::Migration[6.1]
  add_column :import_configs, :encryption_key_name, :string
  add_column :import_configs, :encrypted_passphrase, :string
  add_column :import_configs, :encrypted_passphrase_iv, :string
  add_column :import_configs, :encrypted_secret_key, :string
  add_column :import_configs, :encrypted_secret_key_iv, :string
end
