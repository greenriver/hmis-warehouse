###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        begin
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
        rescue RuntimeError => e
          flash[:error] = "Error contacting MassHealth API: #{e.message}"
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
      file = Health::Enrollment.find(params[:id].to_i)
      self.receiver = Health::Cp.find_by_pidsl(file.receiver_id)
      errors = file.processing_errors

      patients_to_enroll = override_params[:overrides].map { |error| medicaid_id_from_error(error) }.compact
      transactions = file.transactions.select { |transaction| Health::Enrollment.subscriber_id(transaction).in?(patients_to_enroll) }
      transactions.each do |transaction|
        re_enroll_patient(referral(transaction), transaction)
        # Remove the errors from the list that are for this patient
        errors = errors.reject { |error| medicaid_id_from_error(error) == Health::Enrollment.subscriber_id(transaction) }

      rescue Health::MedicaidIdConflict
        # leave the error there
      end
      file.update(processing_errors: errors)

      redirect_to action: :show
    end

    private def medicaid_id_from_error(error)
      # Errors begin with 'ID ' and then the ID is a string of digits
      error.match(/ID (\d+)/).try(:[], 1)
    end

    private def enrollment_params
      params.require(:health_enrollment).permit(:content)
    end

    private def override_params
      params.require(:override).permit(overrides: [])
    end
  end
end
