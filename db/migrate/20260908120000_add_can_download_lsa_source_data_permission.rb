###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Adds can_download_lsa_source_data (see Role.permissions_with_descriptions).
#
# can_export_hmis_data is what governed the LSA source download before this
# permission existed, so those roles are backfilled to keep their access across the
# deploy. Roles added after this runs default to false and must be granted the
# permission deliberately.
class AddCanDownloadLsaSourceDataPermission < ActiveRecord::Migration[7.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information

    Role.where(can_export_hmis_data: true).update_all(can_download_lsa_source_data: true)
  end

  def down
    remove_column :roles, :can_download_lsa_source_data
  end
end
