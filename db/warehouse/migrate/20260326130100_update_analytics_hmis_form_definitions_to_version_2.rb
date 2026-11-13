###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Adds data_source_id to analytics.hmis_form_definitions (v02)
class UpdateAnalyticsHmisFormDefinitionsToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view 'analytics.hmis_form_definitions', version: 2, revert_to_version: 1
  end
end

# rails db:migrate:up:warehouse VERSION=20260326130100
# rails db:migrate:down:warehouse VERSION=20260326130100
