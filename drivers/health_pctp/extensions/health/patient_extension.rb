###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :pctps, class_name: 'HealthPctp::Careplan'
    end
  end
end
