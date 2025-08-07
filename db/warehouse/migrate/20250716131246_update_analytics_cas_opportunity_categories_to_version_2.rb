###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsCasOpportunityCategoriesToVersion2 < ActiveRecord::Migration[7.1]
  def change
    update_view 'analytics.cas_opportunity_categories', version: 2, revert_to_version: 1
  end
end
