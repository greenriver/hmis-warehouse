###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rails.logger.debug "Running initializer in #{__FILE__}"

require File.expand_path('../../lib/util/mail/database_delivery', __dir__)

ActionMailer::Base.add_delivery_method :db, Mail::DatabaseDelivery
ActionMailer::MailDeliveryJob.priority = -5
