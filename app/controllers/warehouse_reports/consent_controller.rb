module WarehouseReports
  class ConsentController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :require_can_confirm_housing_release!, only: [:update_clients]
    def index

      @unconfirmed = client_source.distinct.with_unconfirmed_consent

      @cohorts_for_unconfirmed = begin
        cohorts = {}
        cohort_source.distinct.
          joins(:cohort_clients).
          where(cohort_clients: {client_id: @unconfirmed.select(:id)}).
          pluck(:id, :client_id, :name, :short_name).
          each do |id, client_id, name, short_name|
            cohort_name = short_name.presence || name
            cohorts[id] ||= {name: cohort_name, clients: {}}
            cohorts[id][:clients][client_id] = client_id
        end
        cohorts
      end
      @unconfirmed = @unconfirmed.order(LastName: :asc, FirstName: :asc)
    end

    def update_clients
      to_confirm = params[:clients].try(:[], :confirm_consent).select{|_,value| value.to_i == 1}.map{|id,_| id.to_i} rescue []
      to_activate_in_cas = params[:clients].try(:[], :active_in_cas).select{|_,value| value.to_i == 1}.map{|id,_| id.to_i} rescue []
      release_statuses = params[:clients].try(:[], :housing_release_status).map{|id,v| [id.to_i, v]} rescue []
      if to_confirm.any?
        to_confirm.each do |file_id|
          form = consent_form_source.
            unconfirmed.
            find_by(id: file_id)
          form.confirm_consent!
        end
      end
      if to_activate_in_cas.any?
        # update client.sync_with_cas
        client_source.where(id: to_activate_in_cas).update_all(sync_with_cas: true)
      end

      release_statuses.each do |file_id, release_status|
        release_status = nil if release_status.blank?
        file = consent_form_source.find(file_id)
        Rails.logger.debug "CONSENTFORM: #{file.id} #{file.consent_type} -> #{release_status}"
        file.update(consent_type: release_status)
      end
      flash[:notice] = "Clients updated"
      redirect_to warehouse_reports_consent_index_path
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def cohort_source
      GrdaWarehouse::Cohort
    end

    def cohort_client_source
      GrdaWarehouse::CohortClient
    end

    def consent_form_source
      GrdaWarehouse::ClientFile.consent_forms
    end
  end
end
