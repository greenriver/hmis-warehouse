###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Send
    include ActiveModel::Model

    def initialize(credential)
      @credential = credential
    end

    # @param credential [BuiltForZeroReport::Credential]
    # @param section [BuiltForZeroReport::Adult] or similar
    # @param start_date [Date] Beginning of the month we're submitting
    def send(section, start_date)
      # FIXME: add mini form to pick month and year for submission do submit all of them
      section.section_id(section)
      start_date
    end

    private def section_id(section)
      @credential.section_ids.detect { |m| m['subpopname'] == section.sub_population_name }
    end
  end
end
