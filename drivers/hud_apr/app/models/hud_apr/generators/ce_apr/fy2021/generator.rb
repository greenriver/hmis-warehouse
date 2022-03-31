###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern
    include HudApr::CeAprCellDetailsConcern

    def self.fiscal_year
      'FY 2022'
    end

    def self.generic_title
      'Coordinated Entry Annual Performance Report'
    end

    def self.short_name
      'CE-APR'
    end

    def url
      hud_reports_ce_apr_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::CeApr::Fy2021::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::CeApr::Fy2021::QuestionFive, # Report Validations
        HudApr::Generators::CeApr::Fy2021::QuestionSix, # Data Quality
        HudApr::Generators::CeApr::Fy2021::QuestionSeven, # Persons Served
        HudApr::Generators::CeApr::Fy2021::QuestionEight, # Households Served
        HudApr::Generators::CeApr::Fy2021::QuestionNine, # Participation in Coordinated Entry
        HudApr::Generators::CeApr::Fy2021::QuestionTen, # Total Coordinated Entry Activity During the Year
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
    # Clients in any HMIS project using Method 2 - Active Clients by Date of Service where the enrollment has data in element 4.19 (CE Assessment) with a Date of Assessment in the date range of the report.
    # When including CE Events (element 4.20) for these clients, the system should include data up to 90 days past the report end date. Detailed instructions for this are found on 9c and 9d.
    # Unless otherwise instructed, use data from the enrollment with the latest assessment.
    # Include household members attached to the head of household’s enrollment who were active at the time of that latest assessment, as determined by the household members’ entry and exit dates.

    # Question 10
    # The universe of data for this question is expanded to include all CE activity during the report date range. This includes data in elements 4.19 (CE Assessment) and 4.20 (CE Event) regardless of project or enrollment in which the data was collected.

    # This selects just ids for the clients, to ensure uniqueness, but uses select instead of pluck
    # so that we can find in batches.
    # Find any clients that fit the filter criteria _and_ have at least one assessment in their enrollment
    # occurring within the report range
    def client_scope(start_date: @report.start_date, end_date: @report.end_date)
      household_ids = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: [:assessments, :project] }).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Assessment.within_range(start_date..end_date)).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.heads_of_households).
        pluck(:household_id)

      event_ids = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: [:events, :project] }).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Event.within_range(start_date..end_date)).
        pluck(:client_id)

      scope = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: :project }).
        where(she_t[:household_id].in(household_ids).or(she_t[:client_id].in(event_ids)))

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @report.project_ids

      scope = scope.merge(@filter.apply(GrdaWarehouse::ServiceHistoryEnrollment.all))

      scope.select(:id)
    end
  end
end
