###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateDestinationClientLatestAssessment < ActiveRecord::Migration[7.1]
  def up
    create_view :hmis_destination_client_latest_assessments, version: 1
  end

  def down
    drop_view :hmis_destination_client_latest_assessments
  end
end
