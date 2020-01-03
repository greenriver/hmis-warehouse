###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class ConvertPaymentPremiumFileJob < ActiveJob::Base
    queue_as :low_priority

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
