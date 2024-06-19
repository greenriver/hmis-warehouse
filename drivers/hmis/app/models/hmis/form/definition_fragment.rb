###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A form definition fragment allows for form definitions to be shared and combined across form definitions
# * System-managed fragments are synced from the JSON source in "drivers/hmis/lib/form_data/default" automatically
# * non-system managed fragments are managed through the form editor
class Hmis::Form::DefinitionFragment < ::GrdaWarehouseBase
  self.table_name = :hmis_form_definition_fragments
  acts_as_paranoid
  include ::Hmis::Concerns::HmisArelHelper

  # There is no need to track the JSON blob, because form should be immutable once they are managed through the Form Editor config tool.
  has_paper_trail(
    version: :paper_version, # avoid conflict with the `version` column on the model
    skip: [:template], # skip controls whether paper_trail will save that field with the version record
  )

  # the latest version per identifier
  scope :latest_versions, -> do
    one_for_column([:version], source_arel_table: arel_table, group_on: :identifier)
  end

  def self.publish_new_version!(source)
    if source.new_record?
      source.save!
      return source
    end

    record = source.dup
    record.version += 1
    record.save!
    record
  end
end
