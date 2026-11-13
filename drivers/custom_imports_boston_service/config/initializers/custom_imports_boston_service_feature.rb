###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.custom_imports << 'CustomImportsBostonService::ImportFile'
Rails.application.config.synthetic_event_types << 'CustomImportsBostonService::Synthetic::Event'
