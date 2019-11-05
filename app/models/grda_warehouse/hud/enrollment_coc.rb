###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class EnrollmentCoc < Base
    include HudSharedScopes
    self.table_name = 'EnrollmentCoC'
    self.hud_key = :EnrollmentCoCID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :EnrollmentCoCID,
          :ProjectEntryID,
          :HouseholdID,
          :ProjectID,
          :PersonalID,
          :InformationDate,
          :CoCCode,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      when '6.11', '6.12'
        [
          :EnrollmentCoCID,
          :EnrollmentID,
          :HouseholdID,
          :ProjectID,
          :PersonalID,
          :InformationDate,
          :CoCCode,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :EnrollmentCoCID,
          :EnrollmentID,
          :HouseholdID,
          :ProjectID,
          :PersonalID,
          :InformationDate,
          :CoCCode,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :EnrollmentCoCID,
          :EnrollmentID,
          :HouseholdID,
          :ProjectID,
          :PersonalID,
          :InformationDate,
          :CoCCode,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_enrollment_cocs
    has_one :client, through: :enrollment, inverse_of: :enrollment_cocs
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :enrollment_cocs, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :enrollment_cocs
    has_one :project, through: :enrollment
    belongs_to :data_source

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.coc_codes.none?
        none
      else
        where( CoCCode: user.coc_codes )
      end
    end

    scope :in_coc, -> (coc_code:) do
      where(CoCCode: coc_code)
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
        :ProjectID,
      ]
    end

  end
end