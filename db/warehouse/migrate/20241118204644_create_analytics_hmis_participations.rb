###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsHmisParticipations < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.hmis_participations'
  end
end
