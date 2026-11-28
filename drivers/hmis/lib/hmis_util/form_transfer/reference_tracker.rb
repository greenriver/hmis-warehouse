###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Turns project and organization database ids into HUD IDs for the export, and records which
    # ones were referenced so ProjectExporter includes them.
    class ReferenceTracker
      attr_reader :project_ids, :organization_ids, :warnings

      def initialize(data_source_id:)
        @data_source_id = data_source_id
        @project_ids = Set.new
        @organization_ids = Set.new
        @warnings = []
        @hud_ids = Hash.new { |h, k| h[k] = {} }
      end

      def project_hud_id(id, context:)
        hud_id_for(Hmis::Hud::Project, id, @project_ids, context)
      end

      def organization_hud_id(id, context:)
        hud_id_for(Hmis::Hud::Organization, id, @organization_ids, context)
      end

      private

      def hud_id_for(klass, id, seen, context)
        return if id.blank?

        cache = @hud_ids[klass.name]
        cache[id.to_i] = klass.find_by(id: id, data_source_id: @data_source_id)&.public_send(klass.hud_key) unless cache.key?(id.to_i)
        hud_id = cache[id.to_i]
        if hud_id
          seen << id.to_i
        else
          @warnings << "#{context} points at missing or deleted #{klass.name.demodulize} #{id}"
        end
        hud_id
      end
    end
  end
end
