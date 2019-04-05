module WarehouseReports::Health
  class EligibilityController < ApplicationController
    before_action :require_can_administer_health!
    before_action :set_sender
    before_action :set_reports

    def index
      if inquiry_scope.pending.exists?
        @report = inquiry_scope.pending.first
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
        @report = inquiry_scope.find(params[:id].to_i)
        @report.result = update_params[:content].read
        @report.save!
      rescue
        flash[:error] = 'Error processing uploaded file'
      end
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
      @reports = inquiry_scope.page(params[:page]).per(20)
    end

    def inquiry_scope
      Health::EligibilityInquiry.order(created_at: :desc)
    end
  end
end