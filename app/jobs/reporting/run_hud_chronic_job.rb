###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reporting
  class RunHudChronicJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(client_ids, date)
      # ActiveJob can't serialize a date, so passing string
      date = Date.parse(date)
      disabled_ids = chronically_disabled_client_ids(client_ids, date)

      client_ids.each_with_index do |id, index|
        # Same result as client.hud_chronic?(on_date: date), with the disability check done for the whole batch
        next unless disabled_ids.include?(id)

        client = GrdaWarehouse::Hud::Client.where(id: id).first
        next unless client&.meets_hud_chronic_duration?(on_date: date)

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

    # The disability half of HudChronicDefinition#hud_chronic?, for a whole batch in one query.
    # Limiting to the batch's ids keeps it cheap: the filter carries into the scope's subqueries
    # (~55 ms for 200 clients, vs ~15 s for the system-wide set).
    private def chronically_disabled_client_ids(client_ids, date)
      GrdaWarehouse::Hud::Client.
        destination.
        where(id: client_ids).
        chronically_disabled(date).
        pluck(:id).
        to_set
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
