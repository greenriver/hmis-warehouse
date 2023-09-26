###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  module Tasks
    class CheckConstraints
      include NotifierConfig
      include ::Hmis::Concerns::HmisArelHelper

      def self.check_hud_constraints
        results = {}
        # test_results = {}
        Hmis::Hud::Enrollment.hmis_classes.each do |klass|
          # Client will always fail because of source/destination setup
          next if klass.name == 'Hmis::Hud::Client'

          dupes = klass.group(klass.hud_key, :data_source_id).having(nf('COUNT', [klass.hud_key]).gt(1)).count
          # test_results[klass.name] = dupes.count
          next unless dupes.present?

          results[klass.name] = dupes.count
        end
        if results.present?
          send_single_notification("Found the following duplicate HUD keys, this will prevent adding a DB constraint: #{results}", 'CheckConstraintTask')
        else
          send_single_notification('No duplicate HUD keys found', 'CheckConstraintTask')
        end
        # send_single_notification("Found the following duplicate HUD keys, this will prevent adding a DB constraint: #{test_results}", 'CheckConstraintTask')
      end
    end
  end
end
