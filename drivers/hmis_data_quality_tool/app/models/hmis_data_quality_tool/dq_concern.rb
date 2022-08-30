###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool::DqConcern
  extend ActiveSupport::Concern
  included do
    def self.import_intermediate!(values)
      import!(
        values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: attribute_names.map(&:to_sym),
        },
      )
    end

    def self.section_title(slug)
      sections[slug].try(:[], :title)
    end

    def self.section_description(slug)
      sections[slug].try(:[], :description)
    end
  end
end
