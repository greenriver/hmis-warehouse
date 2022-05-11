###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Disability < Base
    include HudSharedScopes
    include ::HMIS::Structure::Disability
    include RailsDrivers::Extensions

    self.table_name = 'Disabilities'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    attr_accessor :source_id

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :disabilities, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_disabilities, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :disabilities, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :disabilities, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :client, through: :enrollment, inverse_of: :disabilities
    has_one :project, through: :enrollment
    has_one :destination_client, through: :client

    scope :disabled, -> do
      where(DisabilityResponse: positive_responses)
    end

    scope :response_present, -> do
      where(DisabilityResponse: [0, 1, 2, 3])
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
      order(e_t[:EntryDate].desc, d_t[:InformationDate].desc)
    end

    scope :newest_first, -> do
      order(InformationDate: :desc)
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

    def self.positive_responses
      [1, 2, 3].freeze
    end

    # This defines ? methods for each disability type, eg: physical?
    disability_types.each do |hud_key, disability_type|
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
        ::HUD.list('4.10.2', self.DisabilityResponse)
      else
        ::HUD.list('1.8', self.DisabilityResponse)
      end
    end

    def disability_type_text
      ::HUD.disability_type self.DisabilityType
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end
