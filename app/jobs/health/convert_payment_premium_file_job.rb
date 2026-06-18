###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class ConvertPaymentPremiumFileJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform
      Health::PremiumPayment.with_advisory_lock('health_premium_processing') do
        Health::PremiumPayment.unprocessed.each do |hp|
          hp.process!
          NotifyUser.health_premium_payments_finished(hp.user_id).deliver_later
        end
      end
    end
  end
end
