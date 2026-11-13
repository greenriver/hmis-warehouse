###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DropTranslationKeysAndTexts < ActiveRecord::Migration[7.0]
  def up
    drop_table :translation_keys
    drop_table :translation_texts
  end
end
