###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SupplementalEnrollmentData::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :tpc_supplemental_enrollment_datum, class_name: '::SupplementalEnrollmentData::Tpc', foreign_key: :enrollment_id
    end
  end
end
