###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::Health::HousingStatusChanges
  include ArelHelper
  include HealthCharts

  attr_accessor :start_date, :end_date

  def initialize(start_date, end_date, acos = nil, user:)
    @start_date = start_date
    @end_date = end_date
    @range = @start_date..@end_date
    @selected_acos = acos
    @user = user
    @report_data = {}
  end

  def self.url
    'warehouse_reports/health/housing_status_changes'
  end

  def describe
    name_list = aco_names&.join(', ') || 'all ACOs'
    "For #{name_list}, between #{@start_date} and #{@end_date}."
  end

  def aco_names
    return nil unless @selected_acos.present?

    Health::AccountableCareOrganization.find(@selected_acos).pluck(:name)
  end

  def report_data
    populate_report_data unless @report_data.present?
    @report_data
  end

  def unique_client_data
    @unique_client_data ||= report_data.values.uniq
  end

  def data_for_housing_type_chart
    @data_for_housing_type_chart ||= [
      [
        'x',
        'Permanent',
        'Temporary',
        'Doubled Up',
        'Shelter',
        'Street',
        'Unknown',
      ],
      [
        'Starting',
        group_count(group: :starting, status: :permanent),
        group_count(group: :starting, status: :temporary),
        group_count(group: :starting, status: :doubling_up),
        group_count(group: :starting, status: :shelter),
        group_count(group: :starting, status: :street),
        group_count(group: :starting, status: :unknown),
      ],
      [
        'Ending',
        group_count(group: :ending, status: :permanent),
        group_count(group: :ending, status: :temporary),
        group_count(group: :ending, status: :doubling_up),
        group_count(group: :ending, status: :shelter),
        group_count(group: :ending, status: :street),
        group_count(group: :ending, status: :unknown),
      ],
    ]
  end

  def data_for_housing_trend_chart
    @data_for_housing_trend_chart ||= [
      [
        'x',
      ] + trend_categories.keys,
      [
        'Patients',
      ] + trend_group_counts,
    ]
  end

  private def trend_categories
    {
      'Started unhoused, ended housed' => {
        starting_status: unhoused_statuses,
        ending_status: housed_statuses,
      },
      'Started housed, ended unhoused' => {
        starting_status: housed_statuses,
        ending_status: unhoused_statuses,
      },
      'Started housed, ended housed' => {
        starting_status: housed_statuses,
        ending_status: housed_statuses,
      },
      'Started unhoused, ended unhoused' => {
        starting_status: unhoused_statuses,
        ending_status: unhoused_statuses,
      },
    }
  end

  private def trend_group_counts
    trend_categories.values.map { |opts| count_trend_group(opts) }
  end

  private def housed_statuses
    @housed_statuses ||= [:permanent, :temporary]
  end

  private def unhoused_statuses
    @unhoused_statuses ||= [:shelter, :doubling_up, :street, :unknown]
  end

  private def group_count(group:, status:)
    unique_client_data.map(&:values).flatten.select do |c|
      c[group].clean_housing_status == status
    end.count
  end

  private def trend_group(starting_status:, ending_status:)
    unique_client_data.map(&:values).flatten.select do |c|
      c[:starting].clean_housing_status.in?(starting_status) &&
      c[:ending].clean_housing_status.in?(ending_status)
    end
  end

  private def clients_in_trend_group(starting_status:, ending_status:)
    unique_client_data.reduce(&:merge).select do |_, data|
      data[:starting].clean_housing_status.in?(starting_status) &&
      data[:ending].clean_housing_status.in?(ending_status)
    end
  end

  private def count_trend_group(starting_status:, ending_status:)
    trend_group(starting_status: starting_status, ending_status: ending_status).count
  end

  def allowed_status(params)
    trend_categories.keys.detect { |m| m == params.dig(:filter, :status) } || 'Unknown'
  end

  def selected_trend_category(params)
    trend_categories[allowed_status(params)]
  end

  def details_for(params)
    clients_in_trend_group(selected_trend_category(params))
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
            source_visible_to(@user).select(:id),
        ),
      ).where(id: patient_scope.pluck(:client_id)).distinct.index_by(&:id)
    @client_for_id[id]
  end

  def count_for_aco(group:, housing_status:, aco_id:)
    report_data[aco_id].values.map { |a| a[group] }.count { |m| m[:clean_housing_status] == housing_status }
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
      ),
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
    if @report_data[aco_id][client_id][:ending].timestamp < timestamp # rubocop:disable Style/GuardClause
      @report_data[aco_id][client_id][:ending] = OpenStruct.new(
        timestamp: timestamp,
        housing_status: housing_status,
        clean_housing_status: self.class.health_housing_outcome_status(housing_status),
        source: source,
      )
    end
  end
end
