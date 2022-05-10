###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class ClaimsController < ApplicationController
    include ArelHelper
    include ClientPathGenerator
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    before_action :require_can_administer_health!
    before_action :set_report, only: [:show, :destroy, :revise, :accept, :acknowledge, :details, :generate_claims_file]
    before_action :set_sender

    def index
      if Health::Claim.queued.exists?
        @state = :precalculating
        @report = Health::Claim.queued.last
      elsif Health::Claim.precalculated.exists?
        @state = :precalculated
        bucket_results
      elsif Health::Claim.incomplete.exists?
        @state = :running
        @report = Health::Claim.incomplete.last || Health::Claim.queued.last
      elsif Health::Claim.completed.unsubmitted.exists?
        @ta = Health::TransactionAcknowledgement.new
        @state = :unsubmitted
        @report = Health::Claim.completed.unsubmitted.last
      else
        @recent_report = Health::Claim.submitted.order(submitted_at: :desc).limit(1).last
        @completed_reports = Health::Claim.submitted.order(submitted_at: :desc).select(:id, :submitted_at, :max_date, :result)
        @months_unsubmitted = Health::QualifyingActivity.submittable.unsubmitted.
          where.not(date_of_activity: nil).
          distinct.
          order(date_of_activity: :desc).
          pluck(:date_of_activity).map do |date|
            ["#{date.strftime('%B')} - #{date.year}", date.beginning_of_month]
          end.uniq.to_h
        @state = :initial
      end
    end

    def patients
      date = params[:date]&.to_date
      if date.present?
        @month = "#{date.strftime('%B')} - #{date.year}"
        @client_ids = Health::Patient.
          joins(:qualifying_activities).
          merge(Health::QualifyingActivity.submittable.unsubmitted.
            where(date_of_activity: (date.beginning_of_month..date.end_of_month))).
          distinct.
          pluck(:client_id)
        @clients = GrdaWarehouse::Hud::Client.where(id: @client_ids).select(:id, :FirstName, :LastName).
          order(LastName: :asc, FirstName: :asc)
      else
        @month = 'Unknown'
        @client_ids = []
        @clients = []
      end
    end

    def precalculated
      bucket_results
      return unless @report

      render layout: false if request.xhr?
    end

    def qualifying_activities
      force_list = []
      no_force_list = []
      params[:force_payable].each do |qa_id, force_payable|
        if force_payable == 'true'
          force_list << qa_id.to_i
        else
          no_force_list << qa_id.to_i
        end
      end
      Health::QualifyingActivity.unsubmitted.where(id: force_list).
        update_all(force_payable: true)
      Health::QualifyingActivity.unsubmitted.where(id: no_force_list).
        update_all(force_payable: false)

      ignore_list = []
      no_ignore_list = []
      params[:ignored].each do |qa_id, ignore|
        if ignore == 'true'
          ignore_list << qa_id.to_i
        else
          no_ignore_list << qa_id.to_i
        end
      end
      Health::QualifyingActivity.unsubmitted.where(id: ignore_list).
        update_all(ignored: true)
      Health::QualifyingActivity.unsubmitted.where(id: no_ignore_list).
        update_all(ignored: false)

      redirect_to action: :index
    end

    def precalculate
      @report = Health::Claim.new(report_params.merge(user_id: current_user.id))
      begin
        @report.save if @report.valid?
        job = Delayed::Job.enqueue(
          ::Health::QualifyingActivitiesPayabilityJob.new(
            report_id: @report.id,
            current_user_id: current_user.id,
            max_date: @report.max_date,
            test_file: @report.test_file,
          ),
          queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running),
        )
        @report.update(job_id: job.id)
        redirect_to action: :index
      rescue StandardError
        respond_with @report, location: warehouse_reports_health_claims_path
      end
    end

    def show
      respond_to do |format|
        format.text do
          date = @report.submitted_at || Date.current
          response.headers['Content-Disposition'] = "attachment; filename=\"CLAIMS_#{date.strftime('%Y%m%d')}.txt\""
        end
        format.html do
          patient_t = Health::Patient.arel_table
          @qualifying_activities = @report.qualifying_activities.joins(:patient).
            order(patient_t[:last_name].asc, patient_t[:first_name].asc, date_of_activity: :desc)
          @pagy, @qualifying_activities = pagy(@qualifying_activities, items: 100)
        end
      end
    end

    def generate_claims_file
      job = Delayed::Job.enqueue(
        ::Health::ClaimsJob.new(
          report_id: @report.id,
          current_user_id: current_user.id,
          max_date: @report.max_date,
          test_file: @report.test_file,
        ),
        queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running),
      )
      @report.update(job_id: job.id, started_at: Time.now)
      respond_with @report, location: warehouse_reports_health_claims_path
    end

    def destroy
      Health::QualifyingActivity.where(claim_id: @report.id).update_all(claim_submitted_on: nil)
      @report.destroy
      respond_with @report, location: warehouse_reports_health_claims_path
    end

    # def submit
    #   sent_at = Time.now
    #   Health::Claim.transaction do
    #     @report.qualifying_activities.payable.update_all(sent_at: sent_at)
    #     @report.qualifying_activities.unpayable.update_all(claim_submitted_on: nil, claim_id: nil)
    #     @report.update(submitted_at: sent_at)
    #   end
    #   redirect_to action: :index
    # end

    def accept
      @report.update(completed_at: Time.now, result: 'Test', submitted_at: Time.now)
      redirect_to action: :index
    end

    def acknowledge
      ta = Health::TransactionAcknowledgement.create(
        user: current_user,
        content: ta_params[:content].read,
        original_filename: ta_params[:content].original_filename,
      )
      sent_at = Time.now
      claim_result = ta.transaction_result
      if claim_result == 'error'
        flash[:error] = 'Error reading file'
        respond_with @report, location: warehouse_reports_health_claims_path
      else
        Health::Claim.transaction do
          @report.qualifying_activities.payable.update_all(sent_at: sent_at)
          @report.qualifying_activities.unpayable.update_all(claim_submitted_on: nil, claim_id: nil)
          @report.update(submitted_at: sent_at, result: claim_result, transaction_acknowledgement_id: ta.id)
        end
        redirect_to action: :index
      end
    end

    def bucket_results
      @recent_report = Health::Claim.submitted.order(submitted_at: :desc).limit(1).last
      @report = Health::Claim.precalculated.last
      @payable = {}
      @unpayable = {}
      @duplicate = {}
      @valid_unpayable = {}
      return unless @report

      @report.qualifying_activities.joins(:patient).
        preload(patient: :patient_referral).
        order(hp_t[:last_name].asc, hp_t[:first_name].asc, date_of_activity: :desc, id: :asc).
        find_each do |qa|
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
    end

    def details
      @ta = Health::TransactionAcknowledgement.find(@report.transaction_acknowledgement_id)
    end

    def ta_params
      params.require(:health_transaction_acknowledgement).permit(:content)
    end

    def default_options
      {
        max_date: default_date,
      }
    end

    def default_date
      (Date.current - 1.months).end_of_month
    end
    helper_method :default_date

    def report_params
      params.require(:report).permit(
        :max_date,
        :test_file,
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
