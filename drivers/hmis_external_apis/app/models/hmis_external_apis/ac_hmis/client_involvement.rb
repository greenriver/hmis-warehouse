###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ClientInvolvement
    attr_accessor :mci_lookup
    attr_accessor :end_date
    attr_accessor :mci_ids
    attr_accessor :start_date
    attr_accessor :status_message

    def initialize(params)
      self.end_date = params[:end_date]
      self.start_date = params[:start_date]
      self.mci_ids = params[:mci_ids]
    end

    def validate_request!
      message = []

      message << 'mci_ids not provided.' if mci_ids.blank?
      message << 'start_date not provided.' if start_date.blank?
      message << 'end_date not provided.' if end_date.blank?

      begin
        self.start_date = Date.strptime(start_date, '%Y-%m-%d') if start_date.present?
      rescue Date::Error
        message << 'start_date was not formatted correctly.'
      end

      begin
        self.end_date = Date.strptime(end_date, '%Y-%m-%d') if end_date.present?
      rescue Date::Error
        message << 'end_date was not formatted correctly.'
      end

      self.mci_lookup = HmisExternalApis::ExternalId
        .where(value: mci_ids)
        .where(source_type: 'Hmis::Hud::Client')
        .where(namespace: 'ac_hmis_mci')
        .pluck(:source_id, :value) # i.e. client ID and mci ID
        .to_h

      if message.present?
        self.status_message = message.join(' ')
      else
        self.status_message = 'success'
      end
    end

    def ok?
      status_message == 'success'
    end

    def to_json(_ = nil)
      {
        involvements: involvements,
        status_message: status_message,
      }.to_json
    end

    private

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def involvements
      raise 'check validity first' if status_message.nil?

      return [] unless ok?

      clients = Hmis::Hud::Client.where(id: mci_lookup.keys, data_source_id: data_source.id)

      enrollments = Hmis::Hud::Enrollment
        .includes(:client, :project, project: :organization)
        .joins(:client)
        .merge(clients)
        .not_in_progress
        .open_during_range(start_date..end_date)

      enrollments.map do |en|
        {
          entry_date: en.entry_date,
          exit_date: en.exit_date,
          mci_id: mci_lookup[en.client.id],
          personal_id: en.personal_id,
          program_id: en.project_id,
          program_name: en.project.project_name,
          provider_name: en.project.organization.organization_name,
          client_name: en.client.brief_name,
          household_id: en.household_id,
          enrollment_id: en.enrollment_id,
          relationship_to_hoh: en.relationship_to_hoh,
        }
      end
    end
  end
end
