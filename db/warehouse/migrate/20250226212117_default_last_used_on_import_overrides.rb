###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DefaultLastUsedOnImportOverrides < ActiveRecord::Migration[7.0]
  def up
    HmisCsvImporter::ImportOverride.update_all(last_used_on: Date.current)
  end
end
