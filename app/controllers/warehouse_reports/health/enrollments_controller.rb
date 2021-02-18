###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class EnrollmentsController < ApplicationController
    include HealthEnrollment
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
      @enrollment = Health::Enrollment.find(params[:id].to_i)
      filename = "Enrollments #{@enrollment.created_at.to_s(:db)}"
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{filename}.xlsx"
        end
        format.edi do
          send_data(@enrollment.content, filename: "#{filename}.edi")
        end
      end
    end

    def override
      @file = Health::Enrollment.find(params[:id].to_i)
      @transactions = Kaminari.paginate_array(@file.transactions).page(params[:page])
      receiver_id = @file.receiver_id
      @receiver = @receiver = Health::Cp.find_by(
        pid: receiver_id[0...-1],
        sl: receiver_id.last,
      )
      errors = @file.processing_errors

      overrides = override_params[:overrides].map { |p| p.match(/ID (\d*)/).try(:[], 1) }.compact
      transactions = @file.transactions.select { |transaction| Health::Enrollment.subscriber_id(transaction).in?(overrides) }
      transactions.each do |transaction|
        re_enroll_patient(referral(transaction), transaction)
        errors = errors.reject { |error| error.match(/ID (\d*)/).try(:[], 1) == Health::Enrollment.subscriber_id(transaction) }

      rescue Health::MedicaidIdConflict
        # leave the error there
      end
      @file.update(processing_errors: errors)

      render :show
    end

    def enrollment_params
      params.require(:health_enrollment).permit(:content)
    end

    def override_params
      params.require(:override).permit(overrides: [])
    end
  end
end
