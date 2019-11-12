###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class SsmExportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_filter

    def index
    end

    def download
      @ssms = Health::SelfSufficiencyMatrixForm.joins(:patient).completed_within_range(@filter.range).preload(patient: :client)
      @epic_ssms = Health::EpicSsm.joins(:patient).updated_within_range(@filter.range).preload(patient: :client)
      @hmis_ssms = hmis_responses
      set_hmis_data(@hmis_ssms)
      @patients = patients_by_client_id
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=\"SSM-#{@filter.start&.to_date&.strftime('%F')} to #{@filter.end&.to_date&.strftime('%F')}.xlsx\""
        end
      end
    end

    private def set_filter
      options = {}
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::DateRange.new(options)
      @name = 'Self-Sufficiency Matrix'
    end

    def hmis_touch_point_scope
      GrdaWarehouse::HmisForm.health.self_sufficiency.within_range(@filter.range)
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.confidential
    end

    def filter_params
      params.permit(filter: [:start, :end])[:filter]
    end

    def hmis_responses
      hmis_touch_point_scope.select(
        hmis_form_t[:id].to_sql,
        hmis_form_t[:client_id].to_sql,
        hmis_form_t[:answers].to_sql,
        hmis_form_t[:collected_at].to_sql,
        hmis_form_t[:data_source_id].to_sql,
        hmis_form_t[:assessment_id].to_sql,
        hmis_form_t[:site_id].to_sql,
        hmis_form_t[:staff].to_sql,
      ).
        joins(:hmis_assessment, client: :destination_client).
        order(:client_id, :collected_at)
    end

    private def patients_by_client_id
      client_ids = @client_ids.to_a # from HMIS
      client_ids += ::Health::Patient.where(id: @ssms.select(:patient_id)).pluck(:client_id) # from care-hub
      client_ids += ::Health::Patient.joins(:epic_ssms).merge(Health::EpicSsm.where(id: @epic_ssms.select(:id))).pluck(:client_id) # from epic
      ::Health::Patient.where(client_id: client_ids.to_a).
        joins(:careplans).
        index_by(&:client_id)
    end

    private def set_hmis_data(hmis_ssms) # rubocop:disable Naming/AccessorMethodName
      @data = { sections: {} }
      @sections = {}
      @client_ids = Set.new
      hmis_ssms.preload(client: :destination_client).each do |response|
        answers = response.answers
        # client_name = response.client.name
        client_id = response.client.destination_client.id
        @client_ids << client_id
        # date = response.collected_at
        response_id = response.id
        answers[:sections].each do |section|
          title = section[:section_title]
          @sections[title] ||= []
          @data[:sections][title] ||= {}
          section[:questions].each do |question|
            question_text = question[:question]
            @sections[title] |= [question_text] # Union version of += (add if not there) for array
            @data[:sections][title][question_text] ||= {}
            @data[:sections][title][question_text][client_id] ||= {}
            @data[:sections][title][question_text][client_id][response_id] = question[:answer]
          end
        end
      end
    end
  end
end
