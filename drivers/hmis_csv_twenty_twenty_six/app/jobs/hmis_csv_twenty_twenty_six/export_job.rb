###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  class ExportJob < ::ExportBaseJob
    def exporter_base
      HmisCsvTwentyTwentySix::Exporter::Base
    end
  end
end
