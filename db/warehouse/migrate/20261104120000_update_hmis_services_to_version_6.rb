###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Removes the `:: integer` cast on the CustomServices branch's owner_id. With
# both branches emitting bigint, Postgres can push `owner_id = $n` into each
# branch and use the primary key instead of seq-scanning both tables.
#
# Uses replace_view (CREATE OR REPLACE VIEW), not update_view (DROP + CREATE).
# The view's owner_id column is already bigint (the UNION resolves to it), so no
# column type changes and OR REPLACE is accepted. Unlike DROP, it keeps the
# no_modify_hmis_services trigger and the view's GRANTs.
#
# If this hits strong_migrations' lock_timeout waiting for the view's
# AccessExclusiveLock, nothing is committed; re-running the deploy is the recovery.
class UpdateHmisServicesToVersion6 < ActiveRecord::Migration[8.1]
  def up
    replace_view :hmis_services, version: 6, revert_to_version: 5
  end

  def down
    replace_view :hmis_services, version: 5, revert_to_version: 6
  end
end
