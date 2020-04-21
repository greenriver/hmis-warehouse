###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Disability < Base
    include HudSharedScopes
    self.table_name = 'Disabilities'
    include ::HMIS::Structure::Disability

    self.hud_key = :DisabilitiesID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :DisabilitiesID,
          :ProjectEntryID,
          :PersonalID,
          :InformationDate,
          :DisabilityType,
          :DisabilityResponse,
          :IndefiniteAndImpairs,
          :DocumentationOnFile,
          :ReceivingServices,
          :PATHHowConfirmed,
          :PATHSMIInformation,
          :TCellCountAvailable,
          :TCellCount,
          :TCellSource,
          :ViralLoadAvailable,
          :ViralLoad,
          :ViralLoadSource,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      when '6.11', '6.12'
        [
          :DisabilitiesID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :DisabilityType,
          :DisabilityResponse,
          :IndefiniteAndImpairs,
          :TCellCountAvailable,
          :TCellCount,
          :TCellSource,
          :ViralLoadAvailable,
          :ViralLoad,
          :ViralLoadSource,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :DisabilitiesID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :DisabilityType,
          :DisabilityResponse,
          :IndefiniteAndImpairs,
          :TCellCountAvailable,
          :TCellCount,
          :TCellSource,
          :ViralLoadAvailable,
          :ViralLoad,
          :ViralLoadSource,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :DisabilitiesID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :DisabilityType,
          :DisabilityResponse,
          :IndefiniteAndImpairs,
          :TCellCountAvailable,
          :TCellCount,
          :TCellSource,
          :ViralLoadAvailable,
          :ViralLoad,
          :ViralLoadSource,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :disabilities
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_disabilities
    has_one :client, through: :enrollment, inverse_of: :disabilities
    has_one :project, through: :enrollment
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :disabilities, optional: true
    has_one :destination_client, through: :client
    belongs_to :data_source

    scope :disabled, -> do
      where(DisabilityResponse: [1, 2, 3])
    end

    scope :chronically_disabled, -> do
      disabled.where(IndefiniteAndImpairs: 1)
    end

    #################################
    # Standard Cohort Scopes
    scope :veteran, -> do
      joins(:destination_client).merge(GrdaWarehouse::Hud::Client.veteran)
    end

    scope :non_veteran, -> do
      joins(:destination_client).merge(GrdaWarehouse::Hud::Client.non_veteran)
    end

    # End Standard Cohort Scopes
    #################################

    scope :sorted_entry_date_information_date, -> do
      order(e_t[:EntryDate].desc,d_t[:InformationDate].desc)
    end

    scope :physical, -> do
      where(DisabilityType: 5)
    end

    scope :developmental, -> do
      where(DisabilityType: 6)
    end

    scope :chronic, -> do
      where(DisabilityType: 7)
    end

    scope :hiv, -> do
      where(DisabilityType: 8)
    end

    scope :mental, -> do
      where(DisabilityType: 9)
    end

    scope :substance, -> do
      where(DisabilityType: 10)
    end

    def self.disability_types
      {
        5 => :physical,
        6 => :developmental,
        7 => :chronic,
        8 => :hiv,
        9 => :mental,
        10 => :substance,
      }
    end

    # This defines ? methods for each disability type, eg: physical?
    self.disability_types.each do |hud_key, disability_type|
      define_method "#{disability_type}?".to_sym do
        self.DisabilityType == hud_key
      end
    end

    def indefinite_and_impairs?
      self.IndefiniteAndImpairs == 1
    end

    # see Disabilities.csv spec version 5
    def response
      if self.DisabilityType == 10
        ::HUD::list('4.10.2', self.DisabilityResponse)
      else
        ::HUD::list('1.8', self.DisabilityResponse)
      end
    end

    def disability_type_text
      ::HUD::disability_type self.DisabilityType
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end