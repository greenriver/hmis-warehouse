###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class ScheduledDocumentsController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_manage_accountable_care_organizations!
    before_action :set_scheduled_document, only: [:edit, :update, :destroy]

    ALLOWED_DOCUMENT_CLASSES = [
      'Health::ScheduledDocuments::EnrollmentDisenrollment',
    ].freeze

    def index
      @scheduled_documents = scheduled_document_source.all
    end

    def new
      document_type = params[:type]
      raise 'Invalid Document Type' unless ALLOWED_DOCUMENT_CLASSES.include?(document_type)

      @scheduled_document = scheduled_document_source.new(type: document_type)
    end

    def create
      document_type = new_scheduled_document_params[:type]
      raise 'Invalid Document Type' unless ALLOWED_DOCUMENT_CLASSES.include?(document_type)

      scheduled_document = scheduled_document_source.create(type: document_type)
      scheduled_document.update!(scheduled_document_params(scheduled_document))
      redirect_to action: :index
    rescue ActiveRecord::RecordInvalid
      @scheduled_document = scheduled_document
      render :new
    end

    def edit
    end

    def update
      @scheduled_document.update(scheduled_document_params(@scheduled_document))
      redirect_to action: :index
    rescue ActiveRecord::RecordInvalid
      render :edit
    end

    def destroy
      @scheduled_document.destroy
      redirect_to action: :index
    end

    def available_protocols
      {
        sftp: 'SFTP',
      }.invert
    end
    helper_method :available_protocols

    private def set_scheduled_document
      @scheduled_document = scheduled_document_source.find(params[:id])
    end

    private def new_scheduled_document_params
      params.require(:scheduled_document).permit(
        :type,
      )
    end

    private def scheduled_document_params(scheduled_document)
      params.require(:scheduled_document).permit(
        :name,
        :protocol,
        :hostname,
        :port,
        :username,
        :password,
        :file_path,
        *scheduled_document.params,
      )
    end

    private def scheduled_document_source
      Health::ScheduledDocuments::Base
    end
  end
end
