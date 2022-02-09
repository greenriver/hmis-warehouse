###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
  class Base
    include ArelHelper

    def initialize options
      @options = options
    end

    # Scope coming in is based on GrdaWarehouse::ServiceHistoryEnrollment
    def add_filters(scope:)
      # Limit to only those projects the user who queued the report can see
      scope = scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(@report.user))
      project_group_ids = @report.options['project_group_ids'].delete_if(&:blank?).map(&:to_i)
      if project_group_ids.any?
        project_group_project_ids = GrdaWarehouse::ProjectGroup.where(id: project_group_ids).map(&:project_ids).flatten.compact
        @report.options['project_id'] |= project_group_project_ids
      end
      if @report.options['project_id'].delete_if(&:blank?).any?
        project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
        scope = scope.joins(:project).where(Project: { id: project_ids})
      end
      scope = scope.where(data_source_id: @report.options['data_source_id'].to_i) if @report.options['data_source_id'].present?
      scope = scope.where(data_source_id: @report.options['data_source_ids'].select(&:present?).map(&:to_i)) if @report.options['data_source_ids']&.select(&:present?).present?
      scope = scope.coc_funded_in(coc_code: @report.options['coc_code']) if @report.options['coc_code'].present?
      scope = sub_population_scope(scope, @report.options['sub_population']) if @report.options['sub_population'].present?
      scope = race_scope(scope, @report.options['race_code']) if @report.options['race_code'].present?
      scope = ethnicity_scope(scope, @report.options['ethnicity_code']) if @report.options['ethnicity_code'].present?
      scope
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

      # scope = scope.joins(:client).merge(GrdaWarehouse::Hud::Client.send(race_code.to_sym))
      # ActiveRecord uses the last merge if multiple merges are given on the same model
      # we need to use the less efficient where in
      scope.where(client_id: GrdaWarehouse::Hud::Client.send(race_code.to_sym).select(:id))
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

      # scope = scope.joins(:client).merge(GrdaWarehouse::Hud::Client.send(ethnicity_scope))
      # ActiveRecord uses the last merge if multiple merges are given on the same model
      # we need to use the less efficient where in
      scope.where(client_id: GrdaWarehouse::Hud::Client.send(ethnicity_scope).select(:id))
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
        completed_at: Time.current,
      )
    end

    def personal_ids(destination_ids)
      GrdaWarehouse::WarehouseClient.
        where(destination_id: destination_ids).
        distinct.
        pluck(:destination_id, :id_in_source).
        group_by(&:first).transform_values{ |v| v.map(&:last).uniq }
    end
  end
end
