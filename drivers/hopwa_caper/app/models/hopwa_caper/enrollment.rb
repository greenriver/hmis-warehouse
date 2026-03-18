###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper
  class Enrollment < ::HudReports::ReportClientBase
    self.table_name = 'hopwa_caper_enrollments'

    has_many :hud_reports_universe_members,
             -> do
               where(::HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HopwaCaper::Enrollment'))
             end,
             inverse_of: :universe_membership,
             class_name: 'HudReports::UniverseMember',
             foreign_key: :universe_membership_id
    has_many :services, class_name: 'HopwaCaper::Service',
                        foreign_key: [:enrollment_id, :report_instance_id],
                        primary_key: [:enrollment_id, :report_instance_id]
    # source enrollment
    has_many :funders, class_name: 'HopwaCaper::Funder',
                       foreign_key: [:project_id, :report_instance_id],
                       primary_key: [:project_id, :report_instance_id]
    # source enrollment
    belongs_to :enrollment, -> { with_deleted }, class_name: 'GrdaWarehouse::Hud::Enrollment'

    def self.as_report_members
      current_scope.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    scope :within_range, ->(range) {
      a_t = arel_table
      scope = current_scope
      scope = scope.where(a_t[:exit_date].eq(nil).or(a_t[:exit_date].gteq(range.first))) if range.begin
      scope = scope.where(a_t[:entry_date].eq(nil).or(a_t[:entry_date].lteq(range.last))) if range.end
      scope
    }

    # HUD guidance for CAPER/APR reports specifies that unduplicated household counts
    # should be determined by a distinct count of Personal IDs for all Heads of Household.
    # In the warehouse, destination_client_id is used as the stable proxy for Personal ID.
    scope :latest_by_distinct_client_id, -> {
      distinct_on(:destination_client_id).order(destination_client_id: :desc, entry_date: :desc, id: :desc)
    }

    scope :head_of_household, -> { where(relationship_to_hoh: 1) }

    scope :active_after, ->(date) { where('exit_date IS NULL OR exit_date > ?', date) }

    INSURANCE_FIELDS = [
      :InsuranceFromAnySource,
      :Medicaid,
      :Medicare,
      :VAMedicalServices,
      :HIVAIDSAssistance,
      :SCHIP,
      :RyanWhiteMedDent,
    ].freeze
    INCOME_SOURCE_FIELDS = [
      :IncomeFromAnySource,
      :Earned,
      :SocSecRetirement,
      :SSI,
      :SSDI,
      :SNAP, :WIC, :TANF,
      :PrivateDisability,
      :VADisabilityService, :VADisabilityNonService,
      :ChildSupport, :Alimony,
      :WorkersComp,
      :Unemployment,
      :OtherIncomeSource
    ].freeze

    def self.from_hud_record(enrollment:, report:, client:)
      project = enrollment.project
      # get deterministic order
      hiv_disabilities = enrollment.disabilities.
        filter { |r| r.hiv? && r.disability_response == 1 }.
        sort_by(&:id)

      # Determines current income/insurance status using most recent assessment as of report end date
      latest_income_benefit = enrollment.income_benefits.
        select { |r| r.InformationDate && r.InformationDate <= report.end_date }.
        max_by { |r| [r.InformationDate, r.id] }

      income_benefit_source_types = []
      medical_insurance_types = []

      if latest_income_benefit
        income_benefit_source_types = INCOME_SOURCE_FIELDS.filter { |field| latest_income_benefit[field] == 1 }.map(&:to_s).sort
        medical_insurance_types = INSURANCE_FIELDS.filter { |field| latest_income_benefit[field] == 1 }.map(&:to_s).sort

        # Add explicit markers for "No" responses to distinguish from "No Data"
        # Only add if no other specific sources are present to maintain logical consistency
        income_benefit_source_types << 'NoIncomeSource' if latest_income_benefit.IncomeFromAnySource == 0 && income_benefit_source_types.empty?
        medical_insurance_types << 'NoInsuranceSource' if latest_income_benefit.InsuranceFromAnySource == 0 && medical_insurance_types.empty?
      end

      exit = enrollment.exit if enrollment.exit&.exit_date&.<= report.end_date
      new(
        report_instance_id: report.id,
        report_household_id: [enrollment.data_source_id, enrollment.household_id, report.id].join(':'),
        destination_client_id: client.id,
        enrollment_id: enrollment.id,
        personal_id: client.personal_id,

        first_name: client.first_name,
        last_name: client.last_name,

        age: client.age_on([report.start_date, enrollment.entry_date].max),
        dob: client.dob,
        dob_quality: client.dob_data_quality,
        sex: client.sex,
        races: client.race_multi.compact.uniq.sort,
        veteran: client.veteran?,
        percent_ami: enrollment.percent_ami,

        relationship_to_hoh: enrollment.relationship_to_hoh || 99,
        project_id: project.id,
        project_type: project.project_type,
        entry_date: enrollment.entry_date,
        exit_destination: exit&.destination,
        exit_date: exit&.exit_date,
        housing_assessment_at_exit: exit&.housing_assessment,
        subsidy_information: exit&.subsidy_information,
        income_benefit_source_types: income_benefit_source_types.compact.sort.uniq,
        medical_insurance_types: medical_insurance_types.compact.sort.uniq,
        hiv_positive: hiv_disabilities.any?,
        chronically_homeless: enrollment.chronically_homeless_at_start,
        prior_living_situation: enrollment.living_situation || 99,
        rental_subsidy_type: enrollment.rental_subsidy_type,
        viral_load_suppression: hiv_disabilities.any? { |d| d.measured_viral_load&.< 200 },
        ever_prescribed_anti_retroviral_therapy: hiv_disabilities.any? { |d| d.anti_retroviral == 1 },
      )
    end

    def hmis_enrollment_id
      enrollment.enrollment_id
    end

    def to_range
      entry_date..exit_date
    end
  end
end
