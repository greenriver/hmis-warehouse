###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class HousingStatusController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @end_date = params.dig(:filter, :end_date) || Date.today
      @start_date = params.dig(:filter, :start_date) || @end_date - 1.month
      @aco = params.dig(:filter, :aco)&.select{|id| id.present? }

      if @start_date.to_date > @end_date.to_date
        new_start = @end_date
        @end_date = @start_date
        @start_date = new_start
      end

      @report = report_data
    end

    def report_data
      patients_scope = Health::Patient.
        participating.
        joins(:patient_referral)

      patients_scope = patients_scope.where(patient_referrals: {accountable_care_organization_id: @aco}) if @aco.present?

      patients = patients_scope.
        preload(:sdh_case_management_notes, :epic_case_notes).
        select(:id, :client_id, :housing_status_timestamp, :housing_status, :medicaid_id)

      from_patients = patients.select { |patient| patient.housing_status_timestamp.present? }.
        map { |patient| [patient.housing_status_timestamp.to_date, [patient.client_id, patient.housing_status]]}.
        to_h

      from_sdh_notes = {}
      patients.each do |patient|
        patient.sdh_case_management_notes.
          select { |note|  note.housing_status.present? && note.date_of_contact.present? }.
            each do |note|
              from_sdh_notes[note.date_of_contact.to_date] = [patient.client_id, note.housing_status]
            end
      end

      from_epic = {}
      patients.each do |patient|
        patient.epic_case_notes.
          select { |note|  note.homeless_status.present? && note.date_of_contact.present? }.
          each do |note|
          from_sdh_notes[note.date_of_contact.to_date] = [patient.client_id, note.homeless_status]
        end
      end

      from_touchpoints = GrdaWarehouse::Hud::Client.
        where(id: patients.map { | patient| patient.client_id }).
        joins(:case_management_notes).
        where.not(hmis_forms: {housing_status: nil}).
        where(hmis_forms: {collected_at: @start_date..@end_date}).
        pluck('hmis_forms.collected_at', :id, :housing_status).
        to_h

      # combine data sources
      results = Hash.new
      merge_data(from_patients, results)
      merge_data(from_sdh_notes, results)
      merge_data(from_epic, results)
      merge_data(from_touchpoints, results)

      results
    end

    def merge_data(source, target)
      source.each do |date, info|
        target[date] ||= {}
        client_id = info[0]
        status = GrdaWarehouse::Hud::Client.health_housing_outcomes[
          GrdaWarehouse::Hud::Client.clean_health_housing_outcome_answer(info[1])][:status]
        target[date][status] ||= Set.new
        target[date][status] << client_id
      end
    end
  end
end
