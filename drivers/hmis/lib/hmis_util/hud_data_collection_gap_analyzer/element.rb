###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class HudDataCollectionGapAnalyzer
    # One scannable HUD data element: a single form item that stores a value on a HUD
    # table (assessment sub-record, Enrollment, or Exit).
    #
    # Deliberately carries no rule. HUD rules attach to ancestor groups, and whether this
    # element is collected is decided by filtering the whole definition tree for a project
    # -- see HudDataCollectionGapAnalyzer#required_link_ids.
    Element = Struct.new(:role, :link_id, :record_type, :field_name, :item_type, keyword_init: true) do
      # Disability form items address rows on the Disability table discriminated by
      # DisabilityType, rather than distinct columns. Maps field name => [DisabilityType, column].
      DISABILITY_FIELDS = {
        'physicalDisability' => [5, :DisabilityResponse],
        'physicalDisabilityIndefiniteAndImpairs' => [5, :IndefiniteAndImpairs],
        'developmentalDisability' => [6, :DisabilityResponse],
        'chronicHealthCondition' => [7, :DisabilityResponse],
        'chronicHealthConditionIndefiniteAndImpairs' => [7, :IndefiniteAndImpairs],
        'hivAids' => [8, :DisabilityResponse],
        'mentalHealthDisorder' => [9, :DisabilityResponse],
        'mentalHealthDisorderIndefiniteAndImpairs' => [9, :IndefiniteAndImpairs],
        'substanceUseDisorder' => [10, :DisabilityResponse],
        'substanceUseDisorderIndefiniteAndImpairs' => [10, :IndefiniteAndImpairs],
        # HOPWA elements are stored on the HIV/AIDS disability row.
        'tCellCountAvailable' => [8, :TCellCountAvailable],
        'tCellCount' => [8, :TCellCount],
        'tCellSource' => [8, :TCellSource],
        'viralLoadAvailable' => [8, :ViralLoadAvailable],
        'viralLoad' => [8, :ViralLoad],
        'viralLoadSource' => [8, :ViralLoadSource],
        'antiRetroviral' => [8, :AntiRetroviral],
      }.freeze

      # field_names whose HUD column keeps an acronym's original casing, which plain
      # #camelize does not reproduce (e.g. 'ssiAmount'.camelize => 'SsiAmount', not
      # 'SSIAmount').
      COLUMN_OVERRIDES = {
        'ssiAmount' => :SSIAmount,
        'ssdiAmount' => :SSDIAmount,
        'vaDisabilityServiceAmount' => :VADisabilityServiceAmount,
        'vaDisabilityNonServiceAmount' => :VADisabilityNonServiceAmount,
        'tanfAmount' => :TANFAmount,
        'gaAmount' => :GAAmount,
        'connectionWithSoar' => :ConnectionWithSOAR,
        'snap' => :SNAP,
        'wic' => :WIC,
        'tanfChildCare' => :TANFChildCare,
        'tanfTransportation' => :TANFTransportation,
        'otherTanf' => :OtherTANF,
        'schip' => :SCHIP,
        'vhaServices' => :VHAServices,
        'cobra' => :COBRA,
        'adap' => :ADAP,
        'noAdapReason' => :NoADAPReason,
        'enrollmentCoc' => :EnrollmentCoC,
        'dateToStreetEssh' => :DateToStreetESSH,
        'losUnderThreshold' => :LOSUnderThreshold,
        'previousStreetEssh' => :PreviousStreetESSH,
        'dateOfBcpStatus' => :DateOfBCPStatus,
        'eligibleForRhy' => :EligibleForRHY,
        'vamcStation' => :VAMCStation,
        'percentAmi' => :PercentAMI,
        'annualPercentAmi' => :AnnualPercentAMI,
        'hohLeaseholder' => :HOHLeaseholder,
        'disabledHoh' => :DisabledHoH,
        'hh5Plus' => :HH5Plus,
        'cocPrioritized' => :CoCPrioritized,
        'hpScreeningScore' => :HPScreeningScore,
        'cmExitReason' => :CMExitReason,
        # Multi-selects stored across several HUD columns; counting any one is enough for presence.
        'counselingMethods' => :IndividualCounseling,
        'aftercareMethods' => :Telephone,
      }.freeze

      MODEL_NAMES = {
        'INCOME_BENEFIT' => 'GrdaWarehouse::Hud::IncomeBenefit',
        'DISABILITY_GROUP' => 'GrdaWarehouse::Hud::Disability',
        'HEALTH_AND_DV' => 'GrdaWarehouse::Hud::HealthAndDv',
        'EMPLOYMENT_EDUCATION' => 'GrdaWarehouse::Hud::EmploymentEducation',
        'YOUTH_EDUCATION_STATUS' => 'GrdaWarehouse::Hud::YouthEducationStatus',
        'ENROLLMENT' => 'GrdaWarehouse::Hud::Enrollment',
        'EXIT' => 'GrdaWarehouse::Hud::Exit',
      }.freeze

      def disability?
        record_type == 'DISABILITY_GROUP'
      end

      # @return [Integer, nil] DisabilityType this element's row is discriminated by
      def disability_type
        return nil unless disability?

        DISABILITY_FIELDS.fetch(field_name).first
      end

      # @return [Symbol] the HUD column holding this element's value
      def column
        return DISABILITY_FIELDS.fetch(field_name).last if disability?
        return COLUMN_OVERRIDES.fetch(field_name) if COLUMN_OVERRIDES.key?(field_name)

        field_name.camelize.to_sym
      end

      def model_name
        MODEL_NAMES.fetch(record_type)
      end

      def association_name
        ElementRegistry::RECORD_TYPE_ASSOCIATIONS.fetch(record_type)
      end

      # Same HUD column under different link ids (e.g. 3.917A vs 3.917B livingSituation).
      def column_key
        [record_type, disability_type, column]
      end

      # Whether a value of 99 means "data not collected" for this element. Only true for
      # coded (CHOICE) items -- 99 is a legitimate value for a currency amount or a count.
      def coded?
        item_type == 'CHOICE'
      end

      def free_text?
        item_type == 'STRING'
      end
    end
  end
end
