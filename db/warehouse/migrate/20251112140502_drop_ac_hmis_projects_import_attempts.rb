###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DropAcHmisProjectsImportAttempts < ActiveRecord::Migration[7.0]
  def up
    drop_table :ac_hmis_projects_import_attempts if table_exists?(:ac_hmis_projects_import_attempts)
  end

  def down
    create_table :ac_hmis_projects_import_attempts do |t|
      t.string :etag, null: false, comment: 'fingerprint of the file'
      t.string :key, null: false, comment: 'path in an s3 bucket to the file'
      t.string :status, null: false
      t.datetime :attempted_at, comment: 'last time an import was attempted'
      t.timestamps null: false
    end

    add_index :ac_hmis_projects_import_attempts, :etag
    add_index :ac_hmis_projects_import_attempts, [:key, :etag], unique: true
  end
end
