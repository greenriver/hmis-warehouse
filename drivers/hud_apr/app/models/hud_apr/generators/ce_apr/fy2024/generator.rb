###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2024
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern
    include HudApr::CeAprCellDetailsConcern

    def self.fiscal_year
      'FY 2024'
    end

    def self.generic_title
      'Coordinated Entry Annual Performance Report'
    end

    def self.short_name
      'CE-APR'
    end

    def self.file_prefix
      "v1.0 #{short_name} #{fiscal_year}"
    end

    def url
      hud_reports_ce_apr_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.default_project_type_codes
      HudUtility2024.performance_reporting.keys
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::CeApr::Fy2024::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::CeApr::Fy2024::QuestionFive, # Report Validations
        HudApr::Generators::CeApr::Fy2024::QuestionSix, # Data Quality
        HudApr::Generators::CeApr::Fy2024::QuestionSeven, # Persons Served
        HudApr::Generators::CeApr::Fy2024::QuestionEight, # Households Served
        HudApr::Generators::CeApr::Fy2024::QuestionNine, # Participation in Coordinated Entry
        HudApr::Generators::CeApr::Fy2024::QuestionTen, # Total Coordinated Entry Activity During the Year
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 4'
    end

    def needs_ce_assessments?
      true
    end

    # NOTE: Questions 4 through 9
    # Depending on the HMIS implementation and how the CoC’s Coordinated Entry System is set up, CE data could be entered into a single project or scattered
    # across multiple projects in HMIS. Every HMIS project must have a response to data element 2.09 [Coordinated Entry Participation Status]; projects that operate
    # as a Coordinated Entry access point and/or receive referrals through Coordinated Entry processes will be included in the report. If data is collected for 4.19
    # [Coordinated Entry Assessment] and/or 4.20 [Coordinated Entry Event] but the project is indicated at data element 2.09 [Coordinated Entry Participation Status]
    # as not participating in Coordinated Entry as an access point or receiving referrals then the project must be excluded from the report universe.
    # The information to be reported on Coordinated Entry for the APR beginning October 1, 2023, is “system-wide." The system being reported on is the CoC where
    # the Supportive Services Only: Coordinated Entry (SSO: CE) project was funded.

    # Question 10
    # The universe of data for this question is expanded to include all CE activity during the report date range. This includes data in elements 4.19 (CE Assessment) and 4.20 (CE Event) regardless of project or enrollment in which the data was collected.

    # This selects just ids for the clients, to ensure uniqueness, but uses select instead of pluck
    # so that we can find in batches.
    # Find any clients that fit the filter criteria _and_ have at least one assessment or event in their enrollment
    # occurring within the report range
    #
    def client_scope(start_date: @report.start_date, end_date: @report.end_date)
      household_ids = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: [:assessments, :project] }).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Assessment.within_range(start_date..end_date)).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.heads_of_households).
        select(:household_id)

      client_ids_from_events = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: [:events, :project] }).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Event.within_range(start_date..end_date)).
        select(:client_id)

      scope = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: :project }).
        where(
          she_t[:household_id].in(household_ids.arel).
          or(she_t[:client_id].in(client_ids_from_events.arel)),
        )

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @report.project_ids

      scope = scope.merge(@filter.apply(GrdaWarehouse::ServiceHistoryEnrollment.all))

      scope.select(:id)
    end

    # Every HMIS project must have a response to data element 2.09 [Coordinated Entry Participation Status]; projects that operate as a Coordinated Entry access point and/or receive referrals through Coordinated Entry processes will be included in the report. If data is collected for 4.19 [Coordinated Entry Assessment] and/or 4.20 [Coordinated Entry Event] but the project is indicated at data element 2.09 [Coordinated Entry Participation Status] as not participating in Coordinated Entry as an access point or receiving referrals then the project must be excluded from the report universe.
    def active_project_ids
      start_date = @report.start_date
      end_date = @report.end_date
      event_end_date = end_date + 90.days
      project_ids = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: [:assessments, project: :ce_participations] }).
        merge(GrdaWarehouse::Hud::Project.continuum_project).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Assessment.within_range(start_date..end_date)).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.heads_of_households).
        merge(GrdaWarehouse::Hud::CeParticipation.within_range(start_date..end_date).ce_participating).
        pluck(p_t[:id])

      project_ids += client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: [:events, project: :ce_participations] }).
        merge(GrdaWarehouse::Hud::Project.continuum_project).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Event.within_range(start_date..event_end_date)).
        merge(GrdaWarehouse::Hud::CeParticipation.within_range(start_date..event_end_date).ce_participating).
        pluck(p_t[:id])

      project_ids & @report.project_ids
    end
  end
end
