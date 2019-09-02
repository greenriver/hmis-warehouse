###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class WarehouseReport::Health::HousingStatus
  def initialize(start_date, end_date, aco)
    @start_date = start_date
    @end_date = end_date
    @aco = aco
  end

  def report_data
    patients_scope = Health::Patient.
      participating.
      joins(:patient_referral)

    patients_scope = patients_scope.where(patient_referrals: {accountable_care_organization_id: @aco}) if @aco.present?

    from_patients = patients_scope.
      where.not(housing_status_timestamp: nil).
      where(housing_status_timestamp: @start_date..@end_date).
      pluck(:housing_status_timestamp, :client_id, :housing_status).
      map { |patient| [patient[0].to_date, [patient[1], patient[2]]] }.
      to_h

    from_sdh_notes = patients_scope.
      joins(:sdh_case_management_notes).
      where.not(sdh_case_management_notes: {housing_status: nil, date_of_contact: nil}).
      where(sdh_case_management_notes: {date_of_contact: @start_date..@end_date}).
      pluck('sdh_case_management_notes.date_of_contact', :client_id, 'sdh_case_management_notes.housing_status').
      map { |patient| [patient[0].to_date, [patient[1], patient[2]]] }.
      to_h

    from_epic = patients_scope.
      joins(:epic_case_notes).
      where.not(epic_case_notes: {homeless_status: nil, contact_date: nil}).
      where(epic_case_notes: {contact_date: @start_date..@end_date}).
      pluck('epic_case_notes.contact_date', :client_id, 'epic_case_notes.homeless_status').
      map { |patient| [patient[0].to_date, [patient[1], patient[2]]] }.
      to_h

    from_touchpoints = GrdaWarehouse::Hud::Client.
      where(id: patients_scope.pluck(:id)).
      joins(:case_management_notes).
      where.not(hmis_forms: {housing_status: nil}).
      where(hmis_forms: {collected_at: @start_date..@end_date}).
      pluck('hmis_forms.collected_at', :id, :housing_status).
      map { |patient| [patient[0].to_date, [patient[1], patient[2]]] }.
      to_h

    # combine data sources
    results = Hash.new
    merge_data(from_patients, results)
    merge_data(from_sdh_notes, results)
    merge_data(from_epic, results)
    merge_data(from_touchpoints, results)

    results.map do |date, status_counts|
      status_counts.each do |status, counts|
        counts[:percent] = (counts[:active_ids].count / patient_count).round rescue 0
      end
    end
    return results
  end

  def merge_data(source, target)
    source.each do |date, info|
      patient_count = Health::Patient.active_on_date(date).count
      target[date] ||= {
        street: { patient_count: patient_count, active_ids: Set.new, percent: 0 },
        shelter: { patient_count: patient_count, active_ids: Set.new, percent: 0 },
        doubling_up: { patient_count: patient_count, active_ids: Set.new, percent: 0 },
        temporary: { patient_count: patient_count, active_ids: Set.new, percent: 0 },
        permanent: { patient_count: patient_count, active_ids: Set.new, percent: 0 },
      }
      client_id = info[0]
      answer = GrdaWarehouse::Hud::Client.clean_health_housing_outcome_answer(info[1])
      status = GrdaWarehouse::Hud::Client.health_housing_outcomes[answer].try(:[], :status)
      next unless status.present?
      target[date][status][:active_ids] << client_id
    end
  end

end