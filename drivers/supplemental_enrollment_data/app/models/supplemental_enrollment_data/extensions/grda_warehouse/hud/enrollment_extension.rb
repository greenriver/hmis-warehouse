###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SupplementalEnrollmentData::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :tpc_supplemental_enrollment_datum, class_name: '::SupplementalEnrollmentData::Tpc', foreign_key: :enrollment_id
    end
  end
end
