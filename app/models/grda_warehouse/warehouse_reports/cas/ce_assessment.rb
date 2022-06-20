###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::WarehouseReports::Cas::CeAssessment < OpenStruct
  include ArelHelper
  include AvailableSubPopulations

  def initialize filter:
    @filter = filter
    @filter.days_homeless = (@filter.days_homeless.presence || 270).to_i
    @filter.no_assessment_in = (@filter.no_assessment_in.presence || 180).to_i
    @filter.sub_population = self.class.available_sub_populations.values.detect do |m|
      m == @filter.sub_population&.to_sym
    end || :adult
    if project_id_missing?
      @filter.project_id = default_project_id
    else
      @filter.project_id = @filter.project_id.to_i
    end
    super
  end

  def clients
    return GrdaWarehouse::Hud::Client.none if project_id_missing?

    @clients ||= begin
      client_ids = GrdaWarehouse::Hud::Client.destination.distinct.select(:id)
      client_ids = filter_for_homeless_clients_with_ongoing_enrollments(client_ids)
      client_ids = filter_length_of_time_homeless(client_ids)
      client_ids = filter_for_sub_population(client_ids)
      client_ids = filter_for_last_assessment(client_ids)
      # This is a bit awkward but reduces the query time by about 3x
      # in certain permission situations
      GrdaWarehouse::Hud::Client.where(
        id: client_ids.distinct.select(:id)
      ).joins(:processed_service_history).
      preload(:processed_service_history)
    end
  end

  def project_id_missing?
    @filter.project_id.blank?
  end

  private def default_project_id
    available_projects.values.flatten(1).first.last
  end

  def project_name
    GrdaWarehouse::Hud::Project.viewable_by(@filter.user).find_by(id: @filter.project_id)&.ProjectName
  end

  def order
    wcp_t[:days_homeless_last_three_years].desc
  end

  def columns
    [
      c_t[:id],
      c_t[:FirstName],
      c_t[:LastName],
      c_t[:SSN],
      c_t[:DOB],
      wcp_t[:days_homeless_last_three_years],
    ]
  end

  private def vieable_project_ids
    @viewable_project_ids ||= GrdaWarehouse::Hud::Project.
      viewable_by(@filter.user).distinct.select(:id)
  end

  private def filter_for_homeless_clients_with_ongoing_enrollments scope
    scope.joins(:service_history_enrollments).
      merge(
        GrdaWarehouse::ServiceHistoryEnrollment.entry.
        ongoing.
        currently_homeless.
        joins(:project).
        merge(
          GrdaWarehouse::Hud::Project.where(id: @filter.project_id).
           where(id: vieable_project_ids) # Ensure we are only including visible projects
        )
      )
  end

  private def source_clients_with_recent_assessments
    GrdaWarehouse::HmisForm.pathways.
      where(collected_at: (@filter.no_assessment_in.days.ago.to_date..Date.tomorrow)).
      distinct
  end

  private def filter_length_of_time_homeless scope
    scope.joins(:processed_service_history).
      merge(
        GrdaWarehouse::WarehouseClientsProcessed.
          where(literally_homeless_last_three_years: @filter.days_homeless..Float::INFINITY)
      )
  end

  private def filter_for_last_assessment scope
    scope.joins(:warehouse_client_destination).
      merge(
        GrdaWarehouse::WarehouseClient.where.not(
          source_id:  source_clients_with_recent_assessments.select(:client_id)
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
          destination_id: destination_client_scope&.select(:id)
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
        joins(:project, project: [:organization]).
        where(client_id: destination_client_scope&.select(:id)).
        order(first_date_in_program: :desc).
        select(
          :client_id,
          :first_date_in_program,
          :last_date_in_program,
          :project_name,
          :computed_project_type,
          bool_or(p_t[:confidential], o_t[:confidential]).as('confidential'),
        ).each do |enrollment|
          enrollments[enrollment.client_id] ||= enrollment
        end
      enrollments
    end
  end

  private def filter_for_sub_population scope
    scope.joins(:service_history_enrollments).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.send(@filter.sub_population))
  end

  def available_days_since_last_assessment
    options = [
      180,
      270,
      365,
    ]
    options << 0 if Rails.env.development?
    options.freeze
  end

  def available_projects
    @available_projects ||= GrdaWarehouse::Hud::Project.options_for_select(user: @filter.user)
  end
end
