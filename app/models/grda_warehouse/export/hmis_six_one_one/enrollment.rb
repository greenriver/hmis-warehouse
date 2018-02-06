module GrdaWarehouse::Export::HMISSixOneOne
  class Enrollment < GrdaWarehouse::Import::HMISSixOneOne::Enrollment
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :ProjectEntryID,
        :PersonalID,
        :ProjectID,
        :EntryDate,
        :HouseholdID,
        :RelationshipToHoH,
        :ResidencePrior,
        :ResidencePriorLengthOfStay,
        :LOSUnderThreshold,
        :PreviousStreetESSH,
        :DateToStreetESSH,
        :TimesHomelessPastThreeYears,
        :MonthsHomelessPastThreeYears,
        :DisablingCondition,
        :DateOfEngagement,
        :ResidentialMoveInDate,
        :DateOfPATHStatus,
        :ClientEnrolledInPATH,
        :ReasonNotEnrolled,
        :WorstHousingSituation,
        :PercentAMI,
        :LastPermanentStreet,
        :LastPermanentCity,
        :LastPermanentState,
        :LastPermanentZIP,
        :AddressDataQuality,
        :DateOfBCPStatus,
        :FYSBYouth,
        :ReasonNoServices,
        :RunawayYouth,
        :SexualOrientation,
        :FormerWardChildWelfare,
        :ChildWelfareYears,
        :ChildWelfareMonths,
        :FormerWardJuvenileJustice,
        :JuvenileJusticeYears,
        :JuvenileJusticeMonths,
        :UnemploymentFam,
        :MentalHealthIssuesFam,
        :PhysicalDisabilityFam,
        :AlcoholDrugAbuseFam,
        :InsufficientIncome,
        :IncarceratedParent,
        :ReferralSource,
        :CountOutreachReferralApproaches,
        :UrgentReferral,
        :TimeToHousingLoss,
        :ZeroIncome,
        :AnnualPercentAMI,
        :FinancialChange,
        :HouseholdChange,
        :EvictionHistory,
        :SubsidyAtRisk,
        :LiteralHomelessHistory,
        :DisabledHoH,
        :CriminalRecord,
        :SexOffender,
        :DependentUnder6,
        :SingleParent,
        :HH5Plus,
        :IraqAfghanistan,
        :FemVet,
        :HPScreeningScore,
        :ThresholdScore,
        :VAMCStation,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,        
      ]
    )

    # Setup some joins so we can include deleted relationships when appropriate
    belongs_to :client_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Client.name, foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :enrollments
    
    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments
        
    self.hud_key = :ProjectEntryID

    # Replace 5.1 versions with 6.11
    # ProjectEntryID with EnrollmentID etc.
    def self.clean_headers(headers)
      headers.map do |k|
        case k
        when :ProjectEntryID
          :EnrollmentID
        when :ResidencePrior
          :LivingSituation
        when :ResidencePriorLengthOfStay
          :LengthOfStay
        when :ResidentialMoveInDate
          :MoveInDate
        when :FYSBYouth
          :EligibleForRHY
        else
          k
        end
      end
    end

    def self.export! enrollment_scope:, project_scope:, path:, export:
      # include any enrollment within the original scope, plus
      # any modified during the range, regardless of when it was open
      changed_scope = modified_within_range(range: (export.start_date..export.end_date), include_deleted: export.include_deleted)
      if export.include_deleted
        changed_scope = changed_scope.joins(:project_with_deleted, {client_with_deleted: :warehouse_client_source}).merge(project_scope)
      else
        changed_scope = changed_scope.joins(:project, {client: :warehouse_client_source}).merge(project_scope)
      end
      if export.include_deleted
        enrollment_scope = enrollment_scope.joins(client_with_deleted: :warehouse_client_source)
      else
        enrollment_scope = enrollment_scope.joins(client: :warehouse_client_source)
      end

      case export.period_type
      when 4
        union_scope = from(
          arel_table.create_table_alias(
            enrollment_scope.select(*columns_to_pluck, :id, :data_source_id).
              union(
                changed_scope.select(*columns_to_pluck, :id, :data_source_id)
              ),
            table_name
          )
        )
      when 3
        union_scope = enrollment_scope.select(*columns_to_pluck, :id, :data_source_id)
      else
        raise NotImplementedError
      end

      export_to_path(
        export_scope: union_scope, 
        path: path, 
        export: export
      )
    end

    def self.includes_union?
      true
    end

  end
end