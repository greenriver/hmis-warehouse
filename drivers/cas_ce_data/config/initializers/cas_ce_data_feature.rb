###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.synthetic_event_types << 'CasCeData::Synthetic::Event'
Rails.application.config.synthetic_assessment_types << 'CasCeData::Synthetic::Assessment'
