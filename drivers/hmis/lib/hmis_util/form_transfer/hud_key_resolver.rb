###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Picks the local HUD ID for an incoming record: the source ID, unless a local record already
    # uses it and isn't the same record (per `same_record`), then R1-<id>, R2-<id>, and so on.
    # The choice is deterministic, so importing the same file again finds the same records.
    class HudKeyResolver
      MAX_ATTEMPTS = 20

      def initialize(data_source_id:)
        @data_source_id = data_source_id
      end

      # @return [ActiveRecord::Base] an existing (possibly soft-deleted) record, or a new one
      def resolve(klass, source_key, same_record:)
        limit = klass.columns_hash[klass.hud_key.to_s].limit || 32
        candidates(source_key, limit).each do |key|
          existing = klass.with_deleted.find_by(data_source_id: @data_source_id, klass.hud_key => key)
          next if existing && !same_record.call(existing)

          return existing || klass.new(data_source_id: @data_source_id, klass.hud_key => key)
        end
        raise "No free #{klass.hud_key} for #{klass.name} #{source_key} after #{MAX_ATTEMPTS} attempts"
      end

      private

      def candidates(source_key, limit)
        [source_key] + (1..MAX_ATTEMPTS).map { |i| "R#{i}-#{source_key}"[0, limit] }
      end
    end
  end
end
