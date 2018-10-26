module WarehouseReports::Health
  class PatientReferralsController < ApplicationController
    include ArelHelper
    include PjaxModalController
    include WindowClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_administer_health!
    before_action :set_date
    before_action :set_unique_referral_dates
    before_action :set_referral_date
    
    def index
      @patients = patient_source.joins(:patient_referral).
        merge(patient_referral_source.not_confirmed_rejected.referred_on(@referral_date)).
        preload(:client)
    end

    def update
      update_engagment_dates
      redirect_to action: :index
    end

    private 
      def set_date
        @date = Date.today.beginning_of_month.to_date + 3.months
        @date = params[:filter].try(:[], :date).presence || @date
      end

      def set_unique_referral_dates
        @referral_dates ||= patient_referral_source.joins(:patient).distinct.order(effective_date: :desc).
          pluck(:effective_date).map(&:to_date).uniq
      end

      def set_referral_date
        @referral_date = @referral_dates.last
        @referral_date = params[:filter].try(:[], :referral_date).presence&.to_date || @referral_date
      end

      def patient_params
        params.require(:patients)
      end

      def patient_referral_params
        params.require(:patient_referrals).
          permit(:engagement_date)
      end

      def patient_ids_to_update_engagement_dates
        patient_params.select{|id, options| options['engagement_date'] == 'on'}.keys.map(&:to_i)
      end

      def update_engagment_dates
        patient_source.where(id: patient_ids_to_update_engagement_dates).update_all(engagement_date: patient_referral_params[:engagement_date])
      end

      def patient_source
        Health::Patient
      end

      def patient_referral_source
        Health::PatientReferral
      end
  end
end