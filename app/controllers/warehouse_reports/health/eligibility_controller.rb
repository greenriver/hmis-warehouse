###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class EligibilityController < ApplicationController
    before_action :require_can_administer_health!
    before_action :set_sender
    before_action :set_reports

    def index
      @report = filtered_inquiry_scope.pending.first
      if @report.present?
        render :edit
      else
        render :new
      end
    end

    def show
      @report = inquiry_scope.find(params[:id].to_i)
      date = @report.service_date
      response.headers['Content-Disposition'] = "attachment; filename=\"INQUIRY_#{date.strftime('%Y%m%d')}.txt\""
      render layout: false
    end

    def create
      begin
        if params[:commit] == generate_eligibility_file_button_text
          eligibility_date = create_params[:eligibility_date]&.to_date
          @report = Health::EligibilityInquiry.create(service_date: eligibility_date)
          @report.build_inquiry_file
          @report.save!
        else
          eligibility_date_string = create_params[:eligibility_date]
          batch_owner = Health::EligibilityInquiry.create!(service_date: eligibility_date_string&.to_date, has_batch: true)
          Health::CheckPatientEligibilityJob.perform_later(eligibility_date_string, batch_owner.id, current_user)
        end
      rescue Exception
        flash[:error] = 'Unable to create eligibility file.'
      end
      redirect_to action: :index
    end

    def update
      begin
        @report = filtered_inquiry_scope.find(params[:id].to_i)
        Health::EligibilityResponse.create(
          eligibility_inquiry: @report,
          response: update_params[:content].read,
          user: current_user,
          original_filename: update_params[:content].original_filename,
        )
        Health::FlagIneligiblePatientsJob.perform_later(@report.id)
      rescue Exception => e
        flash[:error] = "Error processing uploaded file #{e}"
      end
      redirect_to action: :index
    end

    def destroy
      @report = filtered_inquiry_scope.find(params[:id].to_i)
      @report.destroy
      redirect_to action: :index
    end

    def create_params
      params.require(:report).permit(
        :eligibility_date,
      )
    end

    def update_params
      params.require(:result).permit(
        :content,
      )
    end

    def set_sender
      @sender = Health::Cp.sender.first
    end

    def set_reports
      @reports = filtered_inquiry_scope.page(params[:page]).per(20)
    end

    def filtered_inquiry_scope
      inquiry_scope.select(inquiry_scope.column_names - ['inquiry', 'result'])
    end

    def inquiry_scope
      Health::EligibilityInquiry.where(internal: false).order(id: :desc)
    end

    def generate_eligibility_file_button_text
      'Generate Eligibility File'
    end
    helper_method :generate_eligibility_file_button_text
  end
end
