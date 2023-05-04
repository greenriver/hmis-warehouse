###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ClientInvolvement
    attr_accessor :client_ids
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

      # FIXME: Fetch the right way once it's settled
      self.client_ids = HmisExternalApis::ExternalId.where(value: mci_ids).where(source_type: 'Hmis::Hud::Client').pluck(:source_id)
      # self.client_ids = Hmis::Hud::Client.limit(10).pluck(:PersonalID)

      # Is this an error condition or not?
      # message << 'no clients found' if client_ids.blank?

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

    def involvements
      raise 'check validity first' if status_message.nil?

      return [] unless ok?

      # Pretty unsure about this
      enrollments = Hmis::Hud::Enrollment
        .includes(:client)
        .where({ Client: { PersonalID: client_ids } })
        .open_during_range(start_date..end_date)
      # FIXME: Need to preload/join/include external id for MCI ID and add below

      enrollments.map do |en|
        {
          entry_date: en.entry_date,
          exit_date: en.exit_date,
          mci_id: -999,
          # mci_id: en.client.external_id_for_mci_wip,
          personal_id: en.personal_id,
          program_id: en.program_id,
        }
      end
    end
  end
end
