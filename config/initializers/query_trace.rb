###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

if Rails.env.development? && ENV['DISABLE_AR_QUERY_TRACE'] != 'true'
  require 'active_record_query_trace'
  ActiveRecordQueryTrace.enabled = true
end
