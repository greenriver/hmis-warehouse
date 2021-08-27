###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.title
      'Coordinated Entry Annual Performance Report - FY 2020'
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
        HudApr::Generators::CeApr::Fy2020::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::CeApr::Fy2020::QuestionFive, # Report Validations
        HudApr::Generators::CeApr::Fy2020::QuestionSix, # Data Quality
        HudApr::Generators::CeApr::Fy2020::QuestionSeven, # Persons Served
        HudApr::Generators::CeApr::Fy2020::QuestionEight, # Households Served
        HudApr::Generators::CeApr::Fy2020::QuestionNine, # Participation in Coordinated Entry
        HudApr::Generators::CeApr::Fy2020::QuestionTen, # Total Coordinated Entry Activity During the Year
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
      scope = client_source.
        distinct.
        joins(service_history_enrollments: { enrollment: :assessments }).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date)).
        merge(GrdaWarehouse::Hud::Assessment.within_range(start_date..end_date))

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      she_scope = GrdaWarehouse::ServiceHistoryEnrollment.all
      she_scope = filter_for_projects(she_scope)
      she_scope = filter_for_cocs(she_scope)
      she_scope = filter_for_veteran_status(she_scope)
      she_scope = filter_for_household_type(she_scope)
      she_scope = filter_for_head_of_household(she_scope)
      she_scope = filter_for_age(she_scope)
      she_scope = filter_for_gender(she_scope)
      she_scope = filter_for_race(she_scope)
      she_scope = filter_for_ethnicity(she_scope)
      she_scope = filter_for_sub_population(she_scope)
      scope = scope.merge(she_scope)

      scope.select(:id)
    end

    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(as_t[:AssessmentDate].asc).
        group_by(&:client_id).
        reject { |_, enrollments| nbn_with_no_service?(enrollments.last) }
    end

    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        joins(enrollment: :assessments).
        merge(GrdaWarehouse::Hud::Assessment.within_range(@report.start_date..@report.end_date))
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    # Only include ages for clients who were present on the assessment date
    private def ages_for(household_id, date)
      return [] unless households[household_id]

      households[household_id].reject do |client|
        client.entry_date > date || client.exit_date.present? && client.exit_date < date
      end.map do |client|
        GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob])
      end
    end

    # Only include clients who were present on the assessment date
    private def household_member_data(enrollment, date)
      # return nil unless enrollment[:head_of_household]

      active_members = households[enrollment.household_id] || []
      active_members.reject do |client|
        client.entry_date > date || client.exit_date.present? && client.exit_date < date
      end
    end
  end
end
