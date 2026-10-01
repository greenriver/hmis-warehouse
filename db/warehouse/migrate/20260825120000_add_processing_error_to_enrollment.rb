###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Persists the last rescued error message from RebuildEnrollmentsByBatchJob so the
# data_sources/unprocessed_enrollments drill-down can distinguish "not yet attempted"
# from "errored on last attempt" instead of always showing blank.
class AddProcessingErrorToEnrollment < ActiveRecord::Migration[7.2]
  def change
    add_column :Enrollment, :processing_error, :text
  end
end
