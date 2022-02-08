###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class PatientReferralsController < ApplicationController
    include ArelHelper
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_administer_health!
    before_action :set_date
    before_action :set_unique_referral_dates
    before_action :set_referral_date

    def index
      columns = {
        id: hp_t[:id].to_sql,
        client_id: hp_t[:client_id].to_sql,
        first_name: hp_t[:first_name].to_sql,
        last_name: hp_t[:last_name].to_sql,
        enrollment_start_date: hpr_t[:enrollment_start_date].to_sql,
        engagement_date: hp_t[:engagement_date].to_sql,
        rejected: hpr_t[:rejected].to_sql,
      }
      @patients = patient_source.joins(:patient_referral).
        merge(patient_referral_source.not_confirmed_rejected.referred_on(@referral_date)).
        pluck(*columns.values).map do |row|
          ::OpenStruct.new(Hash[columns.keys.zip(row)])
        end
    end

    def update
      update_engagment_dates
      update_enrollment_start_dates
      redirect_to action: :index
    end

    private

    def set_date
      @date = Date.current.beginning_of_month.to_date + 3.months
      @date = params[:filter].try(:[], :date).presence || @date
    end

    def set_unique_referral_dates
      @referral_dates ||= patient_referral_source.not_confirmed_rejected. # rubocop:disable Naming/MemoizedInstanceVariableName
        joins(:patient).
        distinct.
        order(enrollment_start_date: :desc).
        pluck(:enrollment_start_date).map do |d|
          d&.to_date
        end.uniq
    end

    def set_referral_date
      @referral_date = @referral_dates.first
      @referral_date = params[:filter].try(:[], :referral_date).presence&.to_date || @referral_date
    end

    def patient_params
      params.require(:patients)
    end

    def patient_referral_params
      params.require(:patient_referrals).
        permit(
          :engagement_date,
          :enrollment_start_date,
        )
    end

    def patient_ids_to_update
      patient_params.select { |_id, options| options['engagement_date'] == 'on' }.keys.map(&:to_i)
    end

    def update_engagment_dates
      patient_source.where(id: patient_ids_to_update).update_all(engagement_date: patient_referral_params[:engagement_date].to_date)
    end

    def update_enrollment_start_dates
      patient_referral_source.where(patient_id: patient_ids_to_update).update_all(enrollment_start_date: patient_referral_params[:enrollment_start_date].to_date)
    end

    def patient_source
      Health::Patient
    end

    def patient_referral_source
      Health::PatientReferral
    end
  end
end
