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

  def unique_client_data
    report_data.values.uniq
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
    statuses = patient_scope.
      joins(:sdh_case_management_notes).
      merge(Health::SdhCaseManagementNote.with_housing_status.within_range(@range)).
      pluck(
        :client_id,
        h_sdhcmn_t[:housing_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
        h_sdhcmn_t[:date_of_contact].to_sql,
      )
    add_housing_statuses(statuses: statuses, source: 'Care Hub')
  end

  def from_epic_housing_statuses
    statuses = patient_scope.
      joins(:epic_housing_statuses).
      merge(Health::EpicHousingStatus.within_range(@range)).
      pluck(
        :client_id,
        h_ehs_t[:status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
        h_ehs_t[:collected_on].to_sql,
      )
    add_housing_statuses(statuses: statuses, source: 'EPIC')
  end

  def from_epic_case_notes
    statuses = patient_scope.
      joins(:epic_case_notes).
      merge(Health::EpicCaseNote.with_housing_status.within_range(@range)).
      pluck(
        :client_id,
        h_ecn_t[:homeless_status].to_sql,
        hpr_t[:accountable_care_organization_id].to_sql,
        h_ecn_t[:contact_date].to_sql,
      )
    add_housing_statuses(statuses: statuses, source: 'EPIC')
  end

  def from_touchpoints
    statuses = GrdaWarehouse::Hud::Client.
      where(id: patient_scope.pluck(:client_id)).
      joins(:source_hmis_forms).
      merge(GrdaWarehouse::HmisForm.with_housing_status.within_range(@range)).
      pluck(
        :id,
        hmis_form_t[:housing_status].to_sql,
        hmis_form_t[:collected_at].to_sql,
      )

    statuses = statuses.map do |(client_id, status, timestamp)|
      [
        client_id,
        status,
        aco_id_for_client_id(client_id),
        timestamp,
      ]
    end

    add_housing_statuses(statuses: statuses, source: 'ETO')
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

  def add_housing_statuses(statuses:, source:)
    statuses.each do |(client_id, status, aco_id, timestamp)|
      add_housing_status(timestamp: timestamp.to_date, client_id: client_id, housing_status: status, aco_id: aco_id, source: source)
    end
  end


  def add_housing_status(timestamp:, client_id:, housing_status:, aco_id:, source:)
    @report_data[aco_id] ||= {}
    # Default to the first one we find so that everyone has at least a starting and ending value
    @report_data[aco_id][client_id] ||= {
      starting: OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source,
      ),
      ending: OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source,
      )
    }

    # Move the start back if the next one is older
    if @report_data[aco_id][client_id][:starting].timestamp > timestamp
      @report_data[aco_id][client_id][:starting] = OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source,
      )
    end
    if @report_data[aco_id][client_id][:ending].timestamp < timestamp
      @report_data[aco_id][client_id][:ending] = OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source,
      )
    end
  end
end
