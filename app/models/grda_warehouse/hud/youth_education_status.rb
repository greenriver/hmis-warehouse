###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Hud
  class YouthEducationStatus < Base
    include HudSharedScopes
    include ::HmisStructure::YouthEducationStatus
    include ::HmisStructure::Shared
    # Extensions from drivers — see ADR 0007
    include HmisCsvImporter::GrdaWarehouse::Hud::YouthEducationStatusExtension
    include HmisCsvTwentyTwentyFour::GrdaWarehouse::Hud::YouthEducationStatusExtension
    include HmisCsvTwentyTwentySix::GrdaWarehouse::Hud::YouthEducationStatusExtension

    attr_accessor :source_id

    self.table_name = :YouthEducationStatus
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :youth_education_statuses, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :youth_education_statuses, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :youth_education_statuses, optional: true
    belongs_to :data_source, optional: true
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_youth_education_statuses
    has_one :client, through: :enrollment, inverse_of: :youth_education_statuses

    # hide previous declaration of :importable, we'll use this one
    replace_scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end
  end
end
