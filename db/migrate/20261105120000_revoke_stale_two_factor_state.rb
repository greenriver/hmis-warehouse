###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RevokeStaleTwoFactorState < ActiveRecord::Migration[7.2]
  def up
    return unless AuthMethod.devise?

    User.revoke_stale_two_factor_state!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
