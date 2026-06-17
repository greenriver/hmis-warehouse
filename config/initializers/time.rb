###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rails.logger.debug "Running initializer in #{__FILE__}"

Date::DATE_FORMATS[:default] = '%b %e, %Y'
Time::DATE_FORMATS[:default]= '%b %e, %Y %l:%M %P'
