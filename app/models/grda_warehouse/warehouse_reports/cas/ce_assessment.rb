###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::WarehouseReports::Cas::CeAssessment < OpenStruct
  include ArelHelper

  def initialize filter:
    @filter = filter
    @filter.days_homeless = (@filter.days_homeless.presence || 270).to_i
    @filter.no_assessment_in = (@filter.no_assessment_in.presence || 180).to_i
    @filter.sub_population = available_sub_populations.values.detect do |m|
      m == @filter.sub_population&.to_sym
    end || :individual_adults
    @filter.project_id = @filter.project_id.to_i if @filter.project_id.present?

    super
  end

  def clients
    @clients = filter_for_days_homeless(client_source)
    @clients = filter_for_last_assessment(@clients)
    @clients = filter_for_sub_population(@clients)
    @clients = filter_for_eto_project(@clients)
    @clients = filter_for_ongoing_residential_enrollments(@clients)
    @clients.distinct.
      preload(:processed_service_history)
  end

  def order
    wcp_t[:days_homeless_last_three_years].desc
  end

  def columns
    [
      c_t[:id],
      c_t[:FirstName],
      c_t[:LastName],
      wcp_t[:days_homeless_last_three_years],
    ]
  end

  private def client_source
    # Client#vieable_by returns source clients
    GrdaWarehouse::Hud::Client.destination.
      joins(:warehouse_client_destination).
      merge(
        GrdaWarehouse::WarehouseClient.where(
          source_id: source_client_ids
        )
      )
  end

  private def source_client_ids
    @source_client_ids ||= GrdaWarehouse::Hud::Client.
      viewable_by(@filter.user).
      select(:id)
  end

  private def filter_for_ongoing_residential_enrollments scope
    scope.joins(:service_history_enrollments).
      merge(
        GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing
      )
  end

  private def source_client_ids_with_recent_assessments
    GrdaWarehouse::HmisForm.pathways.
      where(client_id: source_client_ids).
      where(collected_at: (@filter.no_assessment_in.days.ago.to_date..Date.tomorrow)).
      distinct.
      select(:client_id)
  end

  private def filter_for_days_homeless scope
    scope.joins(:processed_service_history).
      merge(
        GrdaWarehouse::WarehouseClientsProcessed.where(
          wcp_t[:days_homeless_last_three_years].gteq(@filter.days_homeless)
        )
      )
  end

  private def filter_for_last_assessment scope
    scope.joins(:warehouse_client_destination).
      merge(
        GrdaWarehouse::WarehouseClient.where(
          source_id: source_client_ids.where.
            not(id: source_client_ids_with_recent_assessments)
        )
      )
  end

  def max_pathways_date(destination_client_scope, client_id)
    assessment_dates(destination_client_scope)[client_id]&.to_date || 'Not assessed'
  end

  private def assessment_dates destination_client_scope
    @assessment_dates ||= GrdaWarehouse::HmisForm.pathways.
      joins(:destination_client).
      where(client_id: GrdaWarehouse::WarehouseClient.where(
          destination_id: destination_client_scope.map(&:id)
        ).select(:source_id)
      ).
      group(wc_t[:destination_id]).
      maximum(hmis_form_t[:collected_at])
  end

  def max_enrollment_for(destination_client_scope, client_id)
    recent_enrollments(destination_client_scope)[client_id]
  end

  private def recent_enrollments destination_client_scope
    @recent_enrollments ||= begin
      enrollments = {}
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        residential.
        where(client_id: destination_client_scope.map(&:id)).
        order(first_date_in_program: :desc).
        select(:client_id, :first_date_in_program, :last_date_in_program, :project_name, :computed_project_type).each do |enrollment|
          enrollments[enrollment.client_id] ||= enrollment
        end
      enrollments
    end
  end

  private def filter_for_sub_population scope
    scope.send(@filter.sub_population)
  end

  private def filter_for_eto_project scope
    return scope unless @filter.project_id.present?

    scope.joins(source_enrollments: :project).
      merge(GrdaWarehouse::Hud::Project.where(id: @filter.project_id))
  end

  def available_sub_populations
    {
      'All Clients' => :all_clients,
      'Veterans' => :veteran,
      'Youth' => :youth,
      'Family' => :family,
      'Children' => :children,
      'Parenting Youth' => :parenting_youth,
      'Parenting Juveniles' => :parenting_children,
      'Unaccompanied Minors' => :unaccompanied_minors,
      'Individual Adults' => :individual_adults,
      'Non-Veterans' => :non_veteran,
    }.sort.to_h.freeze
  end

  def available_days_since_last_assessment
    [
      180,
      270,
      365,
    ].freeze
  end

  def available_projects
    @available_projects ||= GrdaWarehouse::Hud::Project.options_for_select(user: @filter.user)
  end
end