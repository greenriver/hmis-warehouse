###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared behavior for the cohort access audit pages. Each including controller supplies its own
# audit_service_class (the Legacy or Acl reconstruction service). Access requires BOTH the cohort
# edit permission and the user-auditing permission, and the cohort must already be viewable by the
# current user (set_cohort scopes through viewable_by).
module CohortAccessAuditing
  extend ActiveSupport::Concern

  included do
    include CohortAuthorization

    before_action :require_can_configure_cohorts!
    before_action :require_can_audit_users!
    before_action :set_cohort
  end

  def show
    @audit = audit_service_class.new(@cohort)
    respond_to do |format|
      format.html
      format.csv { send_audit_csv }
    end
  end

  def export
    @audit = audit_service_class.new(@cohort)
    send_audit_csv
  end

  private

  def send_audit_csv
    send_data @audit.to_csv, type: 'text/csv', filename: csv_filename
  end

  def csv_filename
    model = audit_service_class.name.demodulize.downcase
    "#{@cohort.name.parameterize}-#{model}-access-audit-#{Date.current.to_fs(:db)}.csv"
  end

  def cohort_id
    params[:cohort_id].to_i
  end
end
