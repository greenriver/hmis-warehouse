# frozen_string_literal: true

class UpdateAnalyticsCustomDataElementDefinitionsToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view 'analytics.custom_data_element_definitions', version: 2, revert_to_version: 1
  end
end
