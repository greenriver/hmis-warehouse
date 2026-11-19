###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddReviewersNotifiedAtToHmisExternalFormSubmissions < ActiveRecord::Migration[8.1]
  def up
    add_column :hmis_external_form_submissions, :reviewers_notified_at, :datetime

    # Treat existing submissions as already notified, so the first notify run doesn't email the backlog
    safety_assured do
      execute <<~SQL
        UPDATE hmis_external_form_submissions SET reviewers_notified_at = created_at WHERE reviewers_notified_at IS NULL
      SQL
    end
  end

  def down
    remove_column :hmis_external_form_submissions, :reviewers_notified_at
  end
end
