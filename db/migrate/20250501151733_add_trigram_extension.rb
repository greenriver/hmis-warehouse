###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTrigramExtension < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
  end
end
