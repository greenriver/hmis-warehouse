###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class HealthPrioritizationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_filter

    def index
      @clients = GrdaWarehouse::Hud::Client.distinct.
        joins(service_history_enrollments: :project).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            service_within_date_range(start_date: @filter.start, end_date: @filter.end),
        ).merge(
          GrdaWarehouse::Hud::Project.viewable_by(current_user).
            where(id: @filter.effective_project_ids),
        )
      @disabilities = client_ids_with_disability_types(@clients)
      @vispdat_disabilities = client_ids_with_vispdat_disability(@clients)
      @vispdats = client_ids_with_vispdats(@clients)
      @clients = @clients.order(DOB: :asc, LastName: :asc, FirstName: :asc)
      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
        end
        format.xlsx do
        end
      end
    end

    # patch client with health_prioritization
    def client
      @client = GrdaWarehouse::Hud::Client.destination.find(params[:id])
      health_prioritized = params.dig(:client, :health_prioritized)
      @client.update(health_prioritized: health_prioritized.presence)
      respond_with(@client, location: warehouse_reports_cas_health_prioritization_index_path(filter: filter_params))
    end

    def set_filter
      @filter = ::Filters::DateRangeAndSources.new(filter_params.merge(user_id: current_user.id))
    end

    def filter_params
      return { project_ids: es_project_ids } unless filter_set?

      allowed = params.require(:filter).
        permit(
          :start,
          :end,
          :project_group_ids,
          project_ids: [],
        )
      allowed[:project_ids].reject!(&:blank?)
      # Prevent triggering "all" projects
      allowed[:project_ids] = [0] if allowed[:project_ids].empty?
      allowed
    end
    helper_method :filter_params

    private def es_project_ids
      GrdaWarehouse::Hud::Project.viewable_by(current_user).es.pluck(:id)
    end

    private def filter_set?
      params[:filter].present?
    end
    helper_method :filter_set?

    private def disability_types
      [
        5, # Physical Disability
        8, # HIV/AIDS
      ]
    end

    private def client_ids_with_disability_types(client_scope)
      GrdaWarehouse::Hud::Client.where(id: client_scope.select(:id)).
        joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Disability.where(DisabilityType: disability_types, IndefiniteAndImpairs: 1)).
        distinct.
        pluck(:id, :DisabilityType).
        group_by(&:first)
    end

    private def client_ids_with_vispdat_disability(client_scope)
      vispdat_disability = client_ids_with_vispdat_disability_from_touch_point(client_scope)
      vispdat_disability.merge(client_ids_with_vispdat_disability_from_warehouse(client_scope))
    end

    private def client_ids_with_vispdats(client_scope)
      vispdat = client_ids_with_vispdat_from_touch_point(client_scope)
      vispdat + client_ids_with_vispdat_from_warehouse(client_scope)
    end

    private def client_ids_with_vispdat_disability_from_touch_point(client_scope)
      GrdaWarehouse::Hud::Client.where(id: client_scope.select(:id)).
        joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.vispdat.where(vispdat_physical_disability_answer: ['Yes', 'No'])).
        order(collected_at: :asc).
        pluck(c_t[:id], hmis_form_t[:vispdat_physical_disability_answer]).
        index_by(&:first) # order clause ensures most-recent response when indexed
    end

    private def client_ids_with_vispdat_from_touch_point(client_scope)
      GrdaWarehouse::Hud::Client.where(id: client_scope.select(:id)).
        distinct.
        joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.vispdat).
        pluck(c_t[:id])
    end

    private def client_ids_with_vispdat_disability_from_warehouse(client_scope)
      GrdaWarehouse::Hud::Client.where(id: client_scope.select(:id)).
        joins(:vispdats).
        merge(GrdaWarehouse::Vispdat::Base.completed.where(chronic_answer: [0, 1])).
        order(submitted_at: :asc).
        pluck(c_t[:id], vispdat_t[:chronic_answer]).
        index_by(&:first). # order clause ensures most-recent response when indexed
        transform_values do |row|
          v = row.last
          v = if v.in?(['chronic_answer_no', 0])
            'No'
          elsif v == 'chronic_answer_yes' || v.positive?
            'Yes'
          end
          [row.first, v]
        end
    end

    private def client_ids_with_vispdat_from_warehouse(client_scope)
      GrdaWarehouse::Hud::Client.where(id: client_scope.select(:id)).
        distinct.
        joins(:vispdats).
        merge(GrdaWarehouse::Vispdat::Base.completed).
        pluck(c_t[:id])
    end
  end
end
