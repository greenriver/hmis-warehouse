###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Service < Base
    include HudSharedScopes
    include ::HMIS::Structure::Service

    self.table_name = 'Services'
    self.hud_key = :ServicesID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :ServicesID,
          :ProjectEntryID,
          :PersonalID,
          :DateProvided,
          :RecordType,
          :TypeProvided,
          :OtherTypeProvided,
          :SubTypeProvided,
          :FAAmount,
          :ReferralOutcome,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      when '6.11', '6.12'
        [
          :ServicesID,
          :EnrollmentID,
          :PersonalID,
          :DateProvided,
          :RecordType,
          :TypeProvided,
          :OtherTypeProvided,
          :SubTypeProvided,
          :FAAmount,
          :ReferralOutcome,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :ServicesID,
          :EnrollmentID,
          :PersonalID,
          :DateProvided,
          :RecordType,
          :TypeProvided,
          :OtherTypeProvided,
          :SubTypeProvided,
          :FAAmount,
          :ReferralOutcome,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :ServicesID,
          :EnrollmentID,
          :PersonalID,
          :DateProvided,
          :RecordType,
          :TypeProvided,
          :OtherTypeProvided,
          :SubTypeProvided,
          :FAAmount,
          :ReferralOutcome,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :data_source, inverse_of: :services
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_services
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :services
    has_one :client, through: :enrollment, inverse_of: :services
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :services, optional: true
    has_one :project, through: :enrollment
    has_one :organization, through: :project

    scope :bed_night, -> { where RecordType: 200 }
    scope :descending, -> { order arel_table[:DateProvided].desc }
    # really, the scope below should just be true, but it isn't; this culls things down to the most recent entry of the given type for the date
    scope :uniqueness_constraint, -> {
      st1 = arel_table
      st2 = st1.dup
      st2.table_alias = 'st2'
      where(
        st2.project(Arel.star).
          where( st2[:data_source_id].eq st1[:data_source_id] ).
          where( st2[:PersonalID].eq st1[:PersonalID] ).
          where( st2[:RecordType].eq st1[:RecordType] ).
          where( st2[:EnrollmentID].eq st1[:EnrollmentID] ).
          where( st2[:DateProvided].eq st1[:DateProvided] ).
          where( st2[:id].gt st1[:id] ).
          exists.not
      )
    }

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end