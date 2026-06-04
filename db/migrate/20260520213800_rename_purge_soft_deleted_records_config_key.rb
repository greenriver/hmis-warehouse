###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Migrate the legacy `purge_soft_deleted_records` AppConfigProperty key
# to the namespaced `purge_soft_deleted_records/enabled` key used by
# SoftDeleteRetentionConfiguration.
class RenamePurgeSoftDeletedRecordsConfigKey < ActiveRecord::Migration[7.2]
  def up
    AppConfigProperty.where(key: 'purge_soft_deleted_records').update_all(key: 'purge_soft_deleted_records/enabled')
  end

  def down
    AppConfigProperty.where(key: 'purge_soft_deleted_records/enabled').update_all(key: 'purge_soft_deleted_records')
  end
end
