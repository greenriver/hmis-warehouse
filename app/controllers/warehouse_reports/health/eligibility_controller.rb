module WarehouseReports::Health
  class EligibilityController < ApplicationController
    before_action :require_can_administer_health!
    before_action :set_sender
    before_action :set_reports

    def index
      @report = inquiry_scope.pending.first
      if @report.present? && @report.inquiry.present?
        render :edit
      else
        render :new
      end
    end

    def show
      @report =inquiry_scope.find(params[:id].to_i)
      date = @report.service_date
      response.headers['Content-Disposition'] = "attachment; filename=\"INQUIRY_#{date.strftime('%Y%m%d')}.txt\""
      render layout: false
    end

    def create
      eligibility_date = create_params[:eligibility_date]&.to_date
      @report = Health::EligibilityInquiry.create(service_date: eligibility_date)
      @report.build_inquiry_file
      @report.save
      redirect_to action: :index
    end

    def update
      begin
        @report = inquiry_scope.select(inquiry_scope.column_names - ['inquiry', 'result']).find(params[:id].to_i)
        Health::EligibilityResponse.create(eligibility_inquiry: @report,
          response: update_params[:content].read,
          user: current_user,
          original_filename: update_params[:content].original_filename)
        Health::FlagIneligiblePatientsJob.perform_later(@report.id)
      rescue Exception => e
        flash[:error] = "Error processing uploaded file #{e}"
      end
      redirect_to action: :index
    end

    def destroy
      @report = inquiry_scope.find(params[:id].to_i)
      @report.destroy
      redirect_to action: :index
    end

    def create_params
      params.require(:report).permit(
        :eligibility_date
      )
    end

    def update_params
      params.require(:result).permit(
          :content
      )
    end

    def set_sender
      @sender = Health::Cp.sender.first
    end

    def set_reports
      @reports = inquiry_scope.select(inquiry_scope.column_names - ['inquiry', 'result']).page(params[:page]).per(20)
    end

    def inquiry_scope
      Health::EligibilityInquiry.order(created_at: :desc)
    end
  end
end