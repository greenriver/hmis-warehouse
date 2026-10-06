###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaYyaFollowupReport
  class Report
    include ArelHelper
    include Filter::FilterScopes

    attr_accessor :start_date, :late_date, :filter

    def initialize(filter_object)
      @filter = filter_object
      filter.require_service_during_range = false
      @end_date = filter_object.on
      @late_date = @end_date - 3.months
      @start_date = @late_date + 1.weeks
      filter.update(start: @start_date, end: @end_date)
    end

    # Each row carries `pii_policy` for displaying the client's name
    def clients
      # A blank form shows no one; otherwise report on the authorized projects
      return [] if filter.project_ids.blank? && filter.age_ranges.blank?
      return [] unless any_authorized_projects?

      @clients ||= begin
        rows = client_scope.pluck(*columns.values).map { |row| Hash[columns.keys.zip(row)] }
        preload_policies
        filter.user.policy_context.preload_client_dependencies(rows.map { |row| row[:id] })
        project_ids_by_client = authorized_project_ids_by_client
        rows.each { |row| row[:pii_policy] = name_policy_for(row[:id], project_ids_by_client.fetch(row[:id], [])) }
        rows.sort_by { |row| row[:last_seen] || row[:engagement_date] }
      end
    end

    def any_authorized_projects?
      authorized_project_ids.present?
    end

    def columns
      window = ::Arel::Nodes::Window.new.partition(c_t[:id])
      {
        id: :id,
        first_name: :FirstName,
        last_name: :LastName,
        engagement_date: she_t[:first_date_in_program].minimum.over(window),
        last_seen: cls_t[:InformationDate].maximum.over(window),
      }
    end

    private def client_scope
      client_with_enrollment_scope.
        left_outer_joins(service_history_enrollments: [enrollment: :current_living_situations]).
        where.not(id: client_with_contact_scope.select(:id))
    end

    private def client_with_enrollment_scope
      ::GrdaWarehouse::Hud::Client.
        distinct.
        joins(:service_history_enrollments).
        merge(enrollment_scope)
    end

    private def client_with_contact_scope
      ::GrdaWarehouse::Hud::Client.
        distinct.
        joins(service_history_enrollments: [enrollment: :current_living_situations]).
        merge(enrollment_scope).
        merge(contact_scope)
    end

    private def enrollment_scope
      # Selected and authorized projects are applied as one merge; merging them separately
      # lets the second `where` on the project id replace the first.
      scope = ::GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:project).
        merge(project_source.where(id: authorized_project_ids))
      scope = filter_for_range(scope)
      filter_for_age(scope)
    end

    # The filter's selected projects, narrowed to those the user can report on;
    # with no projects selected, every project the user can report on
    private def authorized_project_ids
      @authorized_project_ids ||= begin
        projects = project_source
        projects = projects.where(id: filter.effective_project_ids) if filter.project_ids.present?
        projects.pluck(:id)
      end
    end

    private def project_source
      ::GrdaWarehouse::Hud::Project.viewable_by(filter.user, permission: :can_view_assigned_reports)
    end

    private def preload_policies
      filter.user.policy_context.preload_project_dependencies(authorized_project_ids)
    end

    # { client id => [authorized project ids of their in-range enrollments] }
    private def authorized_project_ids_by_client
      enrollment_scope.
        where(client_id: client_scope.select(:id)).
        distinct.
        pluck(:client_id, p_t[:id]).
        group_by(&:first).
        transform_values { |pairs| pairs.map(&:last) }
    end

    # A row aggregates the client's in-range enrollments, so the name shows if any
    # authorized project they were enrolled in allows it.
    private def name_policy_for(client_id, project_ids)
      user = filter.user
      allowed = project_ids.any? { |id| user.reporting_policy_for_project(project_id: id, mode: :browse).can_view_name? }
      policy = allowed ? ::GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance : ::GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
      ::GrdaWarehouse::PiiProvider.restrict(policy, restricted: user.policy_context.client_restricted?(client_id))
    end

    private def contact_scope
      ::GrdaWarehouse::Hud::CurrentLivingSituation.
        between(start_date: @start_date, end_date: @end_date)
    end

    def yya_projects(user)
      filter.project_options_for_select(user: user)
    end

    def available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
      }.freeze
    end
  end
end
