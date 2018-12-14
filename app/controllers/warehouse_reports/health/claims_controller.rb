module WarehouseReports::Health
  class ClaimsController < ApplicationController
    include ArelHelper
    include WindowClientPathGenerator
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!
    before_action :set_report, only: [:show, :destroy, :revise, :submit, :generate_claims_file]
    before_action :set_sender

    def index
      if Health::Claim.queued.exists?
        @state = :precalculating
        @report = Health::Claim.queued.last
      elsif Health::Claim.precalculated.exists?
        @state = :precalculated
        @recent_report = Health::Claim.submitted.order(submitted_at: :desc).limit(1).last
        @report = Health::Claim.precalculated.last
        @payable = {}
        @unpayable = {}
        @duplicate = {}
        @valid_unpayable = {}
        # @report.qualifying_activities.joins(:patient).
        #   preload(:patient).
        #   order(hp_t[:last_name].asc, hp_t[:first_name].asc, date_of_activity: :desc, id: :asc).
        #   each do |qa|
        #   # Bucket results
        #   if qa.duplicate? && qa.naturally_payable?
        #     @duplicate[qa.patient_id] ||= []
        #     @duplicate[qa.patient_id] << qa
        #   elsif qa.naturally_payable? && qa.valid_unpayable?
        #     @valid_unpayable[qa.patient_id] ||= []
        #     @valid_unpayable[qa.patient_id] << qa
        #   elsif ! qa.naturally_payable?
        #     @unpayable[qa.patient_id] ||= []
        #     @unpayable[qa.patient_id] << qa
        #   else
        #     @payable[qa.patient_id] ||= []
        #     @payable[qa.patient_id] << qa
        #   end
        # end
      elsif Health::Claim.incomplete.exists?
        @state = :running
        @report = Health::Claim.incomplete.last || Health::Claim.queued.last
      elsif Health::Claim.completed.unsubmitted.exists?
        @state = :unsubmitted
        @report = Health::Claim.completed.unsubmitted.last
      else
        @recent_report = Health::Claim.submitted.order(submitted_at: :desc).limit(1).last
        @completed_reports = Health::Claim.submitted.order(submitted_at: :desc).select(:id, :submitted_at, :max_date)
        @months_unsubmitted = Health::QualifyingActivity.submittable.unsubmitted.distinct.
          order(date_of_activity: :desc).
          pluck(:date_of_activity).map do |date|
            "#{date.strftime("%B")} - #{date.year}"
          end.uniq
        @state = :initial
      end
    end

    def precalculated
      @recent_report = Health::Claim.submitted.order(submitted_at: :desc).limit(1).last
      @report = Health::Claim.precalculated.last
      return unless @report
      @payable = {}
      @unpayable = {}
      @duplicate = {}
      @valid_unpayable = {}
      @report.qualifying_activities.joins(:patient).
        preload(patient: :patient_referral).
        order(hp_t[:last_name].asc, hp_t[:first_name].asc, date_of_activity: :desc, id: :asc).
        each do |qa|
        # Bucket results
        if qa.duplicate? && qa.naturally_payable?
          @duplicate[qa.patient_id] ||= []
          @duplicate[qa.patient_id] << qa
        elsif qa.naturally_payable? && qa.valid_unpayable?
            @valid_unpayable[qa.patient_id] ||= []
            @valid_unpayable[qa.patient_id] << qa
        elsif ! qa.naturally_payable?
          @unpayable[qa.patient_id] ||= []
          @unpayable[qa.patient_id] << qa
        else
          @payable[qa.patient_id] ||= []
          @payable[qa.patient_id] << qa
        end
      end

      render layout: false if request.xhr?
    end

    def qualifying_activities
      force_list = []
      no_force_list = []
      params[:force_payable].each do |qa_id, force_payable|
        if force_payable == "true"
          force_list << qa_id.to_i
        else
          no_force_list << qa_id.to_i
        end
      end
      Health::QualifyingActivity.unsubmitted.where(id: force_list).
        update_all(force_payable: true)
      Health::QualifyingActivity.unsubmitted.where(id: no_force_list).
        update_all(force_payable: false)

      redirect_to action: :index
    end

    def precalculate
      @report = Health::Claim.new(report_params.merge(user_id: current_user.id))
      begin
        @report.save if @report.valid?
        job = Delayed::Job.enqueue(
          ::WarehouseReports::HealthQualifyingActivitiesPayabilityJob.new(
            report_id: @report.id,
            current_user_id: current_user.id,
            max_date: @report.max_date
          ),
          queue: :low_priority
        )
        @report.update(job_id: job.id)
        redirect_to action: :index
      rescue
        respond_with @report, location: warehouse_reports_health_claims_path
      end
    end

    # def qualifying_activities_for_patients
    #   patient_ids = params[:patient_ids].split(',').compact.map(&:to_i)
    #   qualifying_activities = Health::QualifyingActivity.unsubmitted.
    #     where(patient_id: patient_ids).
    #     order(date_of_activity: :asc, id: :asc).
    #     preload(patient: :client)
    #   @payable = {}
    #   @unpayable = {}
    #   @duplicate = {}
    #   @valid_unpayable = {}
    #   qualifying_activities.each do |qa|
    #     # force re-calculation
    #     qa.calculate_payability!
    #     # Bucket results
    #     if qa.duplicate? && qa.naturally_payable?
    #       @duplicate[qa.patient_id] ||= []
    #       @duplicate[qa.patient_id] << qa
    #     elsif qa.naturally_payable? && qa.valid_unpayable?
    #         @valid_unpayable[qa.patient_id] ||= []
    #         @valid_unpayable[qa.patient_id] << qa
    #     elsif ! qa.naturally_payable?
    #       @unpayable[qa.patient_id] ||= []
    #       @unpayable[qa.patient_id] << qa
    #     else
    #       @payable[qa.patient_id] ||= []
    #       @payable[qa.patient_id] << qa
    #     end
    #   end
    #   render layout: false
    # end

    def show

      respond_to do |format|
        format.text do
          date = @report.submitted_at || Date.today
          response.headers['Content-Disposition'] = "attachment; filename=\"CLAIMS_#{date.strftime('%Y%m%d')}.txt\""
        end
        format.html do
          patient_t = Health::Patient.arel_table
          @qualifying_activities = @report.qualifying_activities.joins(:patient).
            order(patient_t[:last_name].asc, patient_t[:first_name].asc, date_of_activity: :desc).
            page(params[:page]).per(100)
        end
      end
    end

    def generate_claims_file
      job = Delayed::Job.enqueue(
        ::WarehouseReports::HealthClaimsJob.new(
          report_id: @report.id,
          current_user_id: current_user.id,
          max_date: @report.max_date
        ),
        queue: :low_priority
      )
      @report.update(job_id: job.id, started_at: Time.now)
      respond_with @report, location: warehouse_reports_health_claims_path
    end

    def destroy
      Health::QualifyingActivity.where(claim_id: @report.id).update_all(claim_submitted_on: nil)
      @report.destroy
      respond_with @report, location: warehouse_reports_health_claims_path
    end

    def submit
      sent_at = Time.now
      Health::Claim.transaction do
        @report.qualifying_activities.payable.update_all(sent_at: sent_at)
        @report.qualifying_activities.unpayable.update_all(claim_submitted_on: nil, claim_id: nil)
        @report.update(submitted_at: sent_at)
      end
      redirect_to action: :index
    end

    def default_options
      {
        max_date: default_date,
      }
    end

    def default_date
      (Date.today - 1.months).end_of_month
    end
    helper_method :default_date

    def report_params
      params.require(:report).permit(
        :max_date,
      )
    end

    def set_report
      @report = report_scope.find(params[:id].to_i)
    end

    def set_sender
      @sender = Health::Cp.sender.first
    end

    def report_source
      ::Health::Claim
    end

    def report_scope
      report_source.visible_by?(current_user)
    end

    def flash_interpolation_options
      { resource_name: 'Report' }
    end
  end
end