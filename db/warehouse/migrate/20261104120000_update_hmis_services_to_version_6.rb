###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# hmis_services v06:
#
# - Removes the `:: integer` cast on the CustomServices branch's owner_id. With
#   both branches emitting bigint, Postgres can push `owner_id = $n` into each
#   branch and use the primary key instead of seq-scanning both tables.
# - Casts the prefixed id to BIGINT instead of INT. As INT it overflows once a
#   Services id reaches 1,000,000,000 or a CustomServices id reaches 147,483,648,
#   and any query returning that row fails with "integer out of range".
#
# Changing the id column's type rules out CREATE OR REPLACE VIEW, so this uses
# update_view (DROP + CREATE). DROP removes the no_modify_hmis_services trigger,
# so it is recreated after each direction.
#
# If this hits strong_migrations' lock_timeout waiting for the view's
# AccessExclusiveLock, nothing is committed; re-running the deploy is the recovery.
class UpdateHmisServicesToVersion6 < ActiveRecord::Migration[8.1]
  def up
    update_view :hmis_services, version: 6, revert_to_version: 5
    create_no_modify_trigger
  end

  def down
    update_view :hmis_services, version: 5, revert_to_version: 6
    create_no_modify_trigger
  end

  private def create_no_modify_trigger
    safety_assured do
      execute <<~SQL
        CREATE TRIGGER no_modify_hmis_services
        INSTEAD OF UPDATE OR DELETE ON public.hmis_services
        FOR EACH ROW EXECUTE FUNCTION prevent_modification()
      SQL
    end
  end
end
