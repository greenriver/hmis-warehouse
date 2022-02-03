###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::Health::HousingStatus
  include ArelHelper
  include HealthCharts

  def initialize(end_date = Date.current, acos = nil, user:)
    @end_date = end_date
    @start_date = @end_date - 5.years
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
    populate_from_patients
    from_sdh_notes
    from_epic
    from_touchpoints
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

  def populate_from_patients
    patient_scope.
      with_housing_status.
      where(housing_status_timestamp: @range).
      pluck(
        :housing_status_timestamp,
        :client_id,
        :housing_status,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      each do |timestamp, client_id, housing_status, aco_id|
        add_housing_status(
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'EPIC Patient',
        )
      end
  end

  def from_sdh_notes
    patient_scope.
      joins(:sdh_case_management_notes).
      merge(Health::SdhCaseManagementNote.with_housing_status.within_range(@range)).
      pluck(
        h_sdhcmn_t[:date_of_contact].to_sql,
        :client_id,
        h_sdhcmn_t[:housing_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      each do |timestamp, client_id, housing_status, aco_id|
        add_housing_status(
          timestamp: timestamp,
          client_id: client_id,
          housing_status: housing_status,
          aco_id: aco_id,
          source: 'Care Hub',
        )
      end
  end

  def from_epic
    patient_scope.
      joins(:epic_case_notes).
      merge(Health::EpicCaseNote.with_housing_status.within_range(@range)).
      pluck(
        h_ecn_t[:contact_date].to_sql,
        :client_id,
        h_ecn_t[:homeless_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
      ).
      each do |timestamp, client_id, housing_status, aco_id|
        add_housing_status(
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
      pluck(
        hmis_form_t[:collected_at].to_sql,
        :id,
        hmis_form_t[:housing_status].to_sql,
      ).
      each do |timestamp, client_id, housing_status|
        aco_id = aco_id_for_client_id(client_id)
        add_housing_status(
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
            source_visible_to(@user).select(:id),
        ),
      ).where(id: patient_scope.pluck(:client_id)).distinct.index_by(&:id)
    @client_for_id[id]
  end

  def count_for_aco(housing_status:, aco_id:)
    report_data[aco_id].values.count { |m| m[:clean_housing_status] == housing_status }
  end

  def count_for_status(housing_status:)
    report_data.values.flat_map(&:values).count { |m| m[:clean_housing_status] == housing_status }
  end

  def add_housing_status(timestamp:, client_id:, housing_status:, aco_id:, source:)
    @report_data[aco_id] ||= {}
    @report_data[aco_id][client_id] ||= OpenStruct.new(timestamp: nil, housing_status: nil)
    if @report_data[aco_id][client_id][:timestamp].blank? || @report_data[aco_id][client_id][:timestamp] < timestamp # rubocop:disable Style/GuardClause
      @report_data[aco_id][client_id] = OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source,
      )
    end
  end
end
