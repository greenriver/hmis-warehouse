###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Generates the HUD SPM Report Data
# See https://files.hudexchange.info/resources/documents/System-Performance-Measures-HMIS-Programming-Specifications.pdf
# for specifications
module HudSpmReport::Generators::Fy2020
  class Base < ::HudReports::QuestionBase
    def self.question_number
      raise 'TODO'.freeze
    end

    include ArelHelper
    LOOKBACK_STOP_DATE = '2012-10-01'.freeze

    # PH = [3,9,10,13]
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)
    # TH = [2]
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SH = [8]
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)
    # SO = [4]
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)
    RRH = [13].freeze
    PH_PSH = [3, 9, 10].freeze

    private def universe
      add_clients unless clients_populated?
      @universe ||= @report.universe(self.class.question_number)
    end

    def sub_population_scope scope, sub_population
      sub_population = sub_population.to_sym
      scope_hash = {
        youth: scope.unaccompanied_youth,
        family_parents: scope.family_parents,
        parenting_youth: scope.parenting_youth,
        parenting_children: scope.parenting_juvenile,
        youth_families: scope.youth_families,
        unaccompanied_minors: scope.unaccompanied_minors,
      }
      if scope_hash.key?(sub_population)
        scope_hash[sub_population]
      else
        scope.send(sub_population)
      end
    end

    def race_scope scope, race_code
      available_scopes = [
        :race_asian,
        :race_am_ind_ak_native,
        :race_black_af_american,
        :race_native_hi_other_pacific,
        :race_white,
        :race_none,
      ]
      return scope unless available_scopes.include?(race_code.to_sym)

      scope.joins(:client).merge(GrdaWarehouse::Hud::Client.send(race_code.to_sym))
    end

    def ethnicity_scope scope, ethnicity_code
      available_scopes = {
        0 => :ethnicity_non_hispanic_non_latino,
        1 => :ethnicity_hispanic_latino,
        8 => :ethnicity_unknown,
        9 => :ethnicity_refused,
        99 => :ethnicity_not_collected,
      }
      ethnicity_scope = available_scopes[ethnicity_code&.to_i]
      return scope unless ethnicity_scope.present?

      scope.joins(:client).merge(GrdaWarehouse::Hud::Client.send(ethnicity_scope))
    end

    # Age should be calculated at report start or enrollment start, whichever is greater
    def age_for_report(dob:, entry_date:, age:)
      @report_start ||= @report.options['report_start'].to_date
      return age if dob.blank? || entry_date > @report_start

      GrdaWarehouse::Hud::Client.age(dob: dob, date: @report_start)
    end

    def set_report_start_and_end
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def add_support headers:, data:
      {
        headers: headers,
        counts: data,
      }
    end

    def update_report_progress percent:
      @report.update(
        percent_complete: percent,
        results: @answers,
        support: @support,
      )
    end

    def start_report(report)
      # Find the first queued report
      @report = ReportResult.where(
        report: report,
        percent_complete: 0,
      ).first
      return unless @report.present?

      Rails.logger.info "Starting report #{@report.report.name}"
      @report.update(percent_complete: 0.01)
    end

    def finish_report
      @report.update(
        percent_complete: 100,
        results: @answers,
        support: @support,
        completed_at: Time.now,
      )
    end

    def personal_ids(destination_ids)
      GrdaWarehouse::WarehouseClient.
        where(destination_id: destination_ids).
        distinct.
        pluck(:destination_id, :id_in_source).
        group_by(&:first).transform_values { |v| v.map(&:last).uniq }
    end
  end
end
