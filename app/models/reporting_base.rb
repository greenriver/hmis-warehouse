###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

class ReportingBase < ApplicationRecord
  self.abstract_class = true
  include ArelHelper

  connects_to database: { writing: :reporting, reading: :reporting }

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/reporting/migrate', Reporting::SchemaMigration).needs_migration?
  end
end
