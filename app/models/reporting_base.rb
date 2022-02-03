###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportingBase < ApplicationRecord
  include ArelHelper

  self.abstract_class = true

  connects_to database: { writing: :reporting, reading: :reporting }

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/reporting/migrate', Reporting::SchemaMigration).needs_migration?
  end
end
