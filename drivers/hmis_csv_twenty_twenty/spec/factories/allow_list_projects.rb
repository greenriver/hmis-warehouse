###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :allowed_project, class: 'GrdaWarehouse::WhitelistedProjectsForClients' do
    project_id { 'ALLOW' }
  end
end
