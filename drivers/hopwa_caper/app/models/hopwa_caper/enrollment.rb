###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper
  class Enrollment < GrdaWarehouseBase
    include SqlHelper
    self.table_name = 'hopwa_caper_enrollments'

    has_many :services, class_name: 'HopwaCaper::Service', foreign_key: [:hud_enrollment_id, :data_source_id, :report_instance_id], primary_key: [:hud_enrollment_id, :data_source_id, :report_instance_id]

    def self.as_report_members
      all.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    scope :overlapping_range, ->(start_date:, end_date:) {
      where('entry_date <= :end_date AND (exit_date >= :start_date OR exit_date IS NULL)', start_date: start_date, end_date: end_date)
    }

    scope :latest_by_personal_id, -> {
      select('DISTINCT ON (hopwa_caper_enrollments.data_source_id, hopwa_caper_enrollments.hud_personal_id) *').order(data_source_id: :asc, hud_personal_id: :asc, entry_date: :desc, id: :desc)
    }

    def self.tbra_funder
      funders = [
        HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)'),
        HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Transitional Housing (facility based or TBRA)'),
      ]
      where('project_funders <@ ?::integer[]', SqlHelper.quote_sql_array(funders))
    end

    def self.strmu_funder
      funders = [
        HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance'),
      ]
      where('project_funders <@ ?::integer[]', SqlHelper.quote_sql_array(funders))
    end

    def self.php_funder
      funders = [
        HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing Placement'),
      ]
      where('project_funders <@ ?::integer[]', SqlHelper.quote_sql_array(funders))
    end

    def self.head_of_household
      where(relationship_to_hoh: 1)
    end

    def self.from_hud_record(enrollment:, report:)
      project = enrollment.project
      hiv_disabilities = enrollment.disabilities.filter(&:hiv?).sort_by(&:id)
      exit = enrollment.exit
      client = enrollment.client
      new(
        report_instance_id: report.id,
        report_household_id: [enrollment.data_source_id, enrollment.household_id, report.id].join(':'),
        client_id: client.id,
        data_source_id: enrollment.data_source_id,
        hud_personal_id: enrollment.personal_id,
        hud_enrollment_id: enrollment.enrollment_id,
        hud_household_id: enrollment.household_id,

        first_name: client.first_name,
        last_name: client.last_name,

        age: client.age_on([report.start_date, enrollment.entry_date].max),
        dob: client.DOB,
        dob_quality: client.DOBDataQuality,
        genders: client.gender_multi.sort,
        races: client.race_multi.sort,
        veteran: client.veteran_status == 1,

        relationship_to_hoh: enrollment.relationship_to_hoh,
        hud_project_id: project.project_id,
        project_funders: project.funders.map(&:funder).compact.sort,
        entry_date: enrollment.entry_date,
        exit_destination: exit&.destination,
        exit_date: exit&.exit_date,
        housing_assessment_at_exit: exit&.housing_assessment,
        subsidy_information: exit&.enrollment,

        duration_days: ([exit&.exit_date, report.end_date].compact.min - enrollment.entry_date).to_i,

        hiv_positive: hiv_disabilities.any?,
        chronically_homeless: enrollment.chronically_homeless_at_start,
        prior_living_situation: enrollment.LivingSituation || 99,
        viral_load_supression: (hiv_disabilities.any? { |d| d.measured_viral_load&.< 200 }),
        ever_perscribed_anti_retroviral_therapy: (hiv_disabilities.any? { |d| d.anti_retroviral == 1 }),
      )
    end

    def self.detail_headers
      special = ['hud_personal_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |header|
        label = case header
        when 'client_id'
          'Warehouse Client ID'
        when 'hud_personal_id'
          'HMIS Personal ID'
        else
          header.humanize
        end
        [header, label]
      end.to_h
    end
  end
end
