###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_client_merge_audit, class: 'Hmis::ClientMergeAudit' do
    actor { association :user }
    merged_at { Time.current }
    pre_merge_state { [] }
    pre_merge_mappings { {} }
  end
end
