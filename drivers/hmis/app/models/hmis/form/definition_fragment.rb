###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::DefinitionFragment < ::GrdaWarehouseBase
  self.table_name = :hmis_form_definition_fragments
  acts_as_paranoid
  include ::Hmis::Concerns::HmisArelHelper

  # There is no need to track the JSON blob, because form should be immutable once they are managed through the Form Editor config tool.
  # When changes are needed, they will be applied to a duplicated Hmis::Form::Definition with a bumped `version`.
  has_paper_trail(
    version: :paper_version, # dont conflict with `version` column. will this break something? https://github.com/paper-trail-gem/paper_trail#6-extensibility
    skip: [:template], # skip controls whether paper_trail will save that field with the version record
  )

  scope :latest_versions, -> do
    # Returns the latest version per identifier
    one_for_column([:version], source_arel_table: arel_table, group_on: :identifier)
  end

  before_save :set_title_from_identifier, if: -> { title.blank? }

  def set_title_from_identifier
    self.title = identifier&.titleize
  end

  def save_as_new_version!
    if new_record?
      save!
      return self
    end

    record = dup
    record.version += 1
    record.save!
    record
  end
end
