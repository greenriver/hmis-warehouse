###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::PkEnrollmentRelated
  extend ActiveSupport::Concern

  included do
    belongs_to :enrollment, foreign_key: :enrollment_pk, optional: true, class_name: 'Hmis::Hud::Enrollment'
    has_one :project, through: :enrollment

    before_validation :set_hud_enrollment_id_from_enrollment_pk, if: :enrollment_pk_changed?
    def set_hud_enrollment_id_from_enrollment_pk
      self.EnrollmentID = enrollment.EnrollmentID
      self.PersonalID = enrollment.PersonalID
    end

    validate :validate_enrollment_pk
    def validate_enrollment_pk
      if enrollment
        errors.add :enrollment_id, 'does not match DB PK' if self.EnrollmentID != enrollment.EnrollmentID
        errors.add :enrollment_id, 'must match enrollment data source' if data_source_id != enrollment.data_source_id
      else
        errors.add :enrollment_pk, :required
      end
    end
  end
end
