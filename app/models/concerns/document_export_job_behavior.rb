###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DocumentExportJobBehavior
  extend ActiveSupport::Concern

  def perform(export_id:)
    export = load_export(export_id)
    if export
      export.perform
      notify(export)
    else
      Rails.logger.warn("[#{self.class.name}] skipping export id #{export_id}")
    end
  end

  protected

  def notify(export)
    return unless export.completed?

    report = OpenStruct.new(title: export.download_title, url: export.download_url)
    NotifyUser.report_completed(export.user_id, report).deliver_now
  end

  def load_export(id)
    export_scope.
      not_expired.
      with_current_version.
      where(id: id).
      first
  end
end
