###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Removes Hmis::UserAccessControl; see issue #7857.
#
# Nothing ever created these records. HMIS permissions reach an AccessControl
# through a UserGroup, and HmisAdmin::AccessControlsController never permitted a
# direct user assignment — the model was only wired into ACL audit history.
class DropHmisUserAccessControls < ActiveRecord::Migration[7.2]
  def up
    drop_table :hmis_user_access_controls, if_exists: true
  end

  def down
    # Table contents are not restored. The structure is recreated so a rollback
    # leaves a schema that the previous code can still query.
    create_table :hmis_user_access_controls do |t|
      t.bigint :access_control_id
      t.bigint :user_id
      t.datetime :deleted_at, precision: nil
      t.timestamps
    end
    add_index :hmis_user_access_controls, :access_control_id
    add_index :hmis_user_access_controls, :user_id
  end
end
