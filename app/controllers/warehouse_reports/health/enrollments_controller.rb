###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class EnrollmentsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @file = Health::Enrollment.new
      @files = Health::Enrollment.order(created_at: :desc)
    end

    def create
      if params[:commit] == 'Retrieve Enrollments Via API'
        api = Health::Soap::MassHealth.new(test: !Rails.env.production?)
        file_list = api.file_list
        enrollment_payloads = file_list.payloads(Health::Soap::MassHealth::ENROLLMENT_RESPONSE_PAYLOAD_TYPE)
        if enrollment_payloads.present?
          enrollment_payloads.each do |payload|
            errors = []
            response = payload.response
            if response.success?
              file = Health::Enrollment.create(
                user_id: current_user.id,
                content: response.response,
                status: 'processing',
              )
              Health::ProcessEnrollmentChangesJob.perform_later(file.id)
            else
              errors << response.error_message
            end
            flash[:error] = errors.join(', ') if errors.present?
          end
        else
          flash[:error] = 'No 834s found'
        end
      else
        begin
          @file = Health::Enrollment.create(
            user_id: current_user.id,
            content: enrollment_params[:content].read,
            original_filename: enrollment_params[:content].original_filename,
            status: 'processing',
          )
          Health::ProcessEnrollmentChangesJob.perform_later(@file.id)
        rescue Exception => e
          flash[:error] = "Error processing uploaded file #{e}"
        end
      end
      redirect_to action: :index
    end

    def show
      @file = Health::Enrollment.find(params[:id].to_i)
      @transactions = Kaminari.paginate_array(@file.transactions).page(params[:page])
    end

    def download
      enrollment = Health::Enrollment.find(params[:id].to_i)
      send_data(enrollment.content, filename: "Enrollments #{enrollment.created_at}.edi")
    end

    def enrollment_params
      params.require(:health_enrollment).permit(:content)
    end
  end
end
