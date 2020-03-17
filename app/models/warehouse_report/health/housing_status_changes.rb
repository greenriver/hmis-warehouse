###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class WarehouseReport::Health::HousingStatusChanges
  include ArelHelper
  include HealthCharts

  def initialize(start_date, end_date, acos=nil, user:)
    @start_date = start_date
    @end_date = end_date
    @range = @start_date..@end_date
    @selected_acos = acos
    @user = user
    @report_data = {}
  end

  def report_data
    populate_report_data unless @report_data.present?
    @report_data
  end

  def populate_report_data
    from_sdh_notes
    from_epic_housing_statuses
    from_epic_case_notes
    from_touchpoints
    @report_data_present = true
  end

  def patient_scope
    @patient_scope ||= begin
      scope = Health::Patient.
        participating.
        joins(patient_referral: :aco)

      scope = scope.merge(Health::PatientReferral.at_acos(@selected_acos)) if @selected_acos.present?
      scope
    end
  end

  def from_sdh_notes
    patient_scope.
      joins(:sdh_case_management_notes).
      merge(Health::SdhCaseManagementNote.with_housing_status.within_range(@range)).
      group(
        :client_id,
        h_sdhcmn_t[:housing_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      minimum(h_sdhcmn_t[:date_of_contact].to_sql).
      each do |data, timestamp|
        client_id, housing_status, aco_id = data
        add_housing_status(
          group: :starting,
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'Care Hub',
        )
      end

    patient_scope.
      joins(:sdh_case_management_notes).
      merge(Health::SdhCaseManagementNote.with_housing_status.within_range(@range)).
      group(
        :client_id,
        h_sdhcmn_t[:housing_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      maximum(h_sdhcmn_t[:date_of_contact].to_sql).
      each do |data, timestamp|
        client_id, housing_status, aco_id = data
        add_housing_status(
          group: :ending,
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'Care Hub',
        )
      end
  end

  def from_epic_housing_statuses
    patient_scope.
      joins(:epic_housing_statuses).
      merge(Health::EpicHousingStatus.within_range(@range)).
      group(
        :client_id,
        h_ehs_t[:status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      minimum(h_ehs_t[:collected_on].to_sql).
      each do |data, timestamp|
      client_id, housing_status, aco_id = data
      add_housing_status(
        group: :starting,
        timestamp: timestamp,
        client_id: client_id,
        housing_status: housing_status,
        aco_id: aco_id,
        source: 'EPIC',
      )
    end

    patient_scope.
      joins(:epic_case_notes).
      joins(:epic_housing_statuses).
      merge(Health::EpicHousingStatus.within_range(@range)).
      group(
        :client_id,
        h_ehs_t[:status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      maximum(h_ehs_t[:collected_on].to_sql).
      each do |data, timestamp|
      client_id, housing_status, aco_id = data
      add_housing_status(
        group: :ending,
        timestamp: timestamp,
        client_id: client_id,
        housing_status: housing_status,
        aco_id: aco_id,
        source: 'EPIC',
      )
    end
  end

  def from_epic_case_notes
    patient_scope.
      joins(:epic_case_notes).
      merge(Health::EpicCaseNote.with_housing_status.within_range(@range)).
      group(
        :client_id,
        h_ecn_t[:homeless_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      minimum(h_ecn_t[:contact_date].to_sql).
      each do |data, timestamp|
        client_id, housing_status, aco_id = data
        add_housing_status(
          group: :starting,
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'EPIC',
        )
      end

    patient_scope.
      joins(:epic_case_notes).
      merge(Health::EpicCaseNote.with_housing_status.within_range(@range)).
      group(
        :client_id,
        h_ecn_t[:homeless_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      maximum(h_ecn_t[:contact_date].to_sql).
      each do |data, timestamp|
        client_id, housing_status, aco_id = data
        add_housing_status(
          group: :ending,
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'EPIC',
        )
      end
  end

  def from_touchpoints
    GrdaWarehouse::Hud::Client.
      where(id: patient_scope.pluck(:client_id)).
      joins(:source_hmis_forms).
      merge(GrdaWarehouse::HmisForm.with_housing_status.within_range(@range)).
      group(
        :id,
        hmis_form_t[:housing_status].to_sql
      ).
      minimum(hmis_form_t[:collected_at].to_sql).
      each do |data, timestamp|
        client_id, housing_status, aco_id = data
        aco_id = aco_id_for_client_id(client_id)
        add_housing_status(
          group: :starting,
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'ETO',
        )
      end

    GrdaWarehouse::Hud::Client.
      where(id: patient_scope.pluck(:client_id)).
      joins(:source_hmis_forms).
      merge(GrdaWarehouse::HmisForm.with_housing_status.within_range(@range)).
      group(
        :id,
        hmis_form_t[:housing_status].to_sql
      ).
      maximum(hmis_form_t[:collected_at].to_sql).
      each do |data, timestamp|
        client_id, housing_status, aco_id = data
        aco_id = aco_id_for_client_id(client_id)
        add_housing_status(
          group: :ending,
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'ETO',
        )
      end
  end

  def housing_status_buckets
    @housing_status_buckets ||= [
      :street,
      :shelter,
      :doubling_up,
      :temporary,
      :permanent,
      :unknown,
    ]
  end

  def aco_id_for_client_id(client_id)
    @aco_id_for_client_id ||= Health::Patient.joins(:patient_referral).pluck(:client_id, hpr_t[:accountable_care_organization_id].to_sql).to_h
    @aco_id_for_client_id[client_id]
  end

  def aco_for_id(id)
    @acos ||= Health::AccountableCareOrganization.where(id: report_data.keys).index_by(&:id)
    @acos[id]
  end

  def client_for_id(id)
    @client_for_id ||= GrdaWarehouse::Hud::Client.
      joins(:warehouse_client_destination).
      merge(
        GrdaWarehouse::WarehouseClient.where(
          source_id: GrdaWarehouse::Hud::Client.
            visible_in_window_to(@user).select(:id)
        )
      ).where(id: patient_scope.pluck(:client_id)).distinct.index_by(&:id)
    @client_for_id[id]
  end

  def count_for_aco(group:, housing_status:, aco_id:)
    report_data[aco_id].values.map{ |a| a[group] }.count{ |m| m[:clean_housing_status] == housing_status }
  end

  def add_housing_status(group:, timestamp:, client_id:, housing_status:, aco_id:, source:)
    @report_data[aco_id] ||= {}
    @report_data[aco_id][client_id] ||= {starting: OpenStruct.new(timestamp: nil), ending: OpenStruct.new(timestamp: nil)}
    report_client = @report_data[aco_id][client_id][group]
    if report_client[:timestamp].blank? ||
      (group == :starting && report_client[:timestamp] > timestamp) ||
      (group == :ending && report_client[:timestamp] < timestamp)
      @report_data[aco_id][client_id][group] = OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source
      )
    end
  end
end
