module WarehouseReports::Health
  class ClaimsController < ApplicationController
    include WindowClientPathGenerator
    before_action :require_can_administer_health!
    # before_action :set_reports, only: [:index, :running]
    before_action :set_report, only: [:show, :destroy, :revise, :submit]
    before_action :set_sender

    def index
      @max_date = Date.today
      @start_date = @max_date - 6.months
      @slice_size = 3
      @patient_ids = Health::Patient.order(last_name: :asc, first_name: :asc).
        joins(:patient_referral).
        with_unsubmitted_qualifying_activities_within(@start_date..@max_date).distinct.
        pluck(:id, :first_name, :last_name).map(&:first)
    end

    def running
    end

    def qualifying_activities
      qa_ids = params[:force_payable].keys.map(&:to_i)
      @qas = Health::QualifyingActivity.unsubmitted.where(id: qa_ids).
        index_by(&:id)

      params[:force_payable].each do |qa_id, force_payable|
        qa = @qas[qa_id.to_i]
        qa.force_payable = force_payable == "true"
        qa.save(validate: false) if qa.changed?
        qa.reload
      end
      redirect_to action: :index
    end

    def qualifying_activities_for_patients
      patient_ids = params[:patient_ids].split(',').compact.map(&:to_i)
      qualifying_activities = Health::QualifyingActivity.unsubmitted.
        where(patient_id: patient_ids).
        order(date_of_activity: :asc, id: :asc).
        preload(patient: :client)
      @payable = {}
      @unpayable = {}
      @duplicate = {}
      qualifying_activities.each do |qa|
        # force re-calculation
        qa.calculate_payability!
        # Bucket results
        if ! qa.naturally_payable? && ! qa.duplicate?
          @unpayable[qa.patient_id] ||= []
          @unpayable[qa.patient_id] << qa
        elsif qa.duplicate?
          @duplicate[qa.patient_id] ||= []
          @duplicate[qa.patient_id] << qa
        else
          @payable[qa.patient_id] ||= []
          @payable[qa.patient_id] << qa
        end
      end
      raise 'hi'
      render layout: false
    end

    def show
      patient_t = Health::Patient.arel_table
      @qualifying_activities = @report.qualifying_activities.joins(:patient).
        order(patient_t[:last_name].asc, patient_t[:first_name].asc, date_of_activity: :desc).
        page(params[:page]).per(100)
    end

    def create
      @report = Health::Claim.create!(report_params.merge(user_id: current_user.id))
      job = Delayed::Job.enqueue(
        ::WarehouseReports::HealthClaimsJob.new(
          report_params.merge(
            report_id: @report.id, current_user_id: current_user.id
          )
        ),
        queue: :low_priority
      )
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_health_claims_path
    end

    def destroy

    end

    def revise
      if @report.submitted?
        respond_with @report, location: warehouse_reports_health_claim_path(@report)
      end
      @report.destroy
      @report = Health::Claim.create!({max_date: @report.max_date, user_id: current_user.id})
      job = Delayed::Job.enqueue(
        ::WarehouseReports::HealthClaimsJob.new(
          {
            max_date: @report.max_date,
            report_id: @report.id,
            current_user_id: current_user.id,
          }
        ),
        queue: :low_priority
      )
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_health_claims_path()
    end

    def submit
      submitted_at = Time.now
      Health::Claim.transaction do
        @report.qualifying_activities.update_all(claim_submitted_on: submitted_at)
        @report.update(submitted_at: submitted_at)
      end
      redirect_to action: :show
    end

    def set_reports
      @reports = report_scope.order(created_at: :desc).page(params[:page]).per(20)
    end

    def default_options
      {
        max_date: 1.days.ago.to_date,
      }
    end

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