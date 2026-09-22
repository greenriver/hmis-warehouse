###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/hud-reporting/csv-export.md
module HmisCsvTwentyTwentySix
  class ExportJob < ::ExportBaseJob
    def exporter_base
      HmisCsvTwentyTwentySix::Exporter::Base
    end
  end
end
