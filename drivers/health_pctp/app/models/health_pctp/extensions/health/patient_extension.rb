###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthPctp::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :pctps, class_name: 'HealthPctp::Careplan'
    end
  end
end
