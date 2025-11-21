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
    has_many :services, class_name: 'HopwaCaper::Service', primary_key: :enrollment_id
    belongs_to :enrollment, -> { with_deleted }, class_name: 'GrdaWarehouse::Hud::Enrollment'

    def project_id
      enrollment.project.id
    end

    def self.as_report_members
      current_scope.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    scope :overlapping_range, ->(start_date:, end_date:) {
      table = arel_table
      where(
        table[:entry_date].lteq(end_date).and(
          table[:exit_date].gteq(start_date).or(table[:exit_date].eq(nil)),
        ),
      )
    }

    scope :latest_by_distinct_client_id, -> {
      distinct_on(:destination_client_id).order(destination_client_id: :desc, entry_date: :desc, id: :desc)
    }

    scope :head_of_household, -> { where(relationship_to_hoh: 1) }

    INSURANCE_FIELDS = [
      :Medicaid,
      :Medicare,
      :VAMedicalServices,
      :HIVAIDSAssistance,
      :SCHIP,
      :RyanWhiteMedDent,
    ].freeze
    INCOME_SOURCE_FIELDS = [
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
      hiv_disabilities = enrollment.disabilities.filter(&:hiv?).sort_by(&:id)

      report_date_range = report.start_date..report.end_date
      income_benefit_source_types = enrollment.income_benefits.flat_map do |record|
        next unless record.InformationDate.in?(report_date_range)

        INCOME_SOURCE_FIELDS.filter { |field| record[field] == 1 }
      end
      medical_insurance_types = enrollment.income_benefits.flat_map do |record|
        next unless record.InformationDate.in?(report_date_range)

        INSURANCE_FIELDS.filter { |field| record[field] == 1 }
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
        races: client.race_multi.sort,
        veteran: client.veteran?,
        percent_ami: enrollment.percent_ami,

        relationship_to_hoh: enrollment.relationship_to_hoh || 99,
        project_funders: project.funders.map(&:funder).compact.sort,
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

    def self.detail_headers
      special = ['personal_id', 'hmis_enrollment_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at', 'report_instance_id', 'enrollment_id', 'report_household_id']
      # Move 'sex' to appear right after 'races' (which should be near gender-related columns)
      other_cols = column_names - special - remove - ['sex']
      cols = special + other_cols

      # Insert 'sex' after 'races' if races exists, otherwise add near the front
      races_index = cols.index('races')
      if races_index
        cols.insert(races_index + 1, 'sex')
      else
        cols.insert(special.length, 'sex')
      end

      cols.map do |header|
        label = case header
        when 'destination_client_id'
          'Warehouse Client ID'
        when 'personal_id'
          'HMIS Personal ID'
        when 'hmis_enrollment_id'
          'HMIS Enrollment ID'
        else
          header.humanize
        end
        [header, label]
      end.to_h
    end

    private

    def transform_value(column, value, pii_policy)
      return HudHelper.util('2026').sex(value) if column == 'sex'
      return HudHelper.util('2026').percent_ami(value) if column == 'percent_ami'

      super
    end
  end
end
