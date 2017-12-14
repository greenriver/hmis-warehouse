module GrdaWarehouse::Hud
  class Disability < Base
    include HudSharedScopes
    self.table_name = 'Disabilities'
    self.hud_key = 'DisabilitiesID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "DisabilitiesID",
        "ProjectEntryID",
        "PersonalID",
        "InformationDate",
        "DisabilityType",
        "DisabilityResponse",
        "IndefiniteAndImpairs",
        "DocumentationOnFile",
        "ReceivingServices",
        "PATHHowConfirmed",
        "PATHSMIInformation",
        "TCellCountAvailable",
        "TCellCount",
        "TCellSource",
        "ViralLoadAvailable",
        "ViralLoad",
        "ViralLoadSource",
        "DataCollectionStage",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ].freeze
    end

    belongs_to :direct_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:PersonalID, :data_source_id], inverse_of: :direct_disabilities
    has_one :client, through: :enrollment, inverse_of: :disabilities
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :disabilities
    has_one :project, through: :enrollment
    belongs_to :export, class_name: 'GrdaWarehouse::Hud::Export', primary_key: [:ExportID, :data_source_id], foreign_key: [:ExportID, :data_source_id], inverse_of: :disabilities
    has_one :destination_client, through: :client

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
  end
end