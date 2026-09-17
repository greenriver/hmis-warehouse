###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsClientPiisToVersion2 < ActiveRecord::Migration[7.2]
  def change
    # update_view (drop + create) is used instead of replace_view (CREATE OR
    # REPLACE VIEW) because installs differ on the underlying Client.SSN
    # column's length modifier (varchar(9) vs unbounded varchar), and
    # CREATE OR REPLACE VIEW cannot change a view column's type.
    update_view 'analytics.client_piis', version: 2, revert_to_version: 1
  end
end
