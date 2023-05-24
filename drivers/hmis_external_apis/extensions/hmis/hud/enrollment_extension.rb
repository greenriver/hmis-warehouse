###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module EnrollmentExtension
        extend ActiveSupport::Concern

        included do
          has_many :external_referrals, class_name: 'HmisExternalApis::AcHmis::Referral', dependent: :destroy
        end
      end
    end
  end
end
