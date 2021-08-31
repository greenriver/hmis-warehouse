###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class RunHudChronicJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(client_ids, date)
      # ActiveJob can't serialize a date, so passing string
      date = Date.parse(date)

      client_ids.each_with_index do |id, index|
        client = GrdaWarehouse::Hud::Client.where(id: id).first
        next unless client&.hud_chronic?(on_date: date)

        log " #{index} => Client #{id} is HUD chronic"

        data = client.hud_chronic_data

        hc = GrdaWarehouse::HudChronic.new
        hc.date = date
        hc.client_id = id
        hc.months_in_last_three_years = data[:months_in_last_three_years]
        hc.individual = !client.presented_with_family?(after: date - 3.years, before: date)
        hc.age = client.age_on(date)
        hc.homeless_since = client.date_of_first_service
        hc.dmh = any_dmh_for?(client_id: id, on_date: date)
        hc.trigger = data[:trigger]

        hc.save
      end
    end

    def any_dmh_for?(client_id:, on_date:)
      @dmh_ids ||= GrdaWarehouse::Hud::Organization.dmh.ids
      GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing(on_date: on_date).where(client_id: client_id, organization_id: @dmh_ids).any?
    end

    def log(msg, underline: false)
      return unless Rails.env.development?

      Rails.logger.info msg
      Rails.logger.info '=' * msg.length if underline
    end
  end
end
