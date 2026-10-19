###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ProjectDataQualityReportMailer < DatabaseMailer
  def report_complete(projects, report, contact)
    @projects = projects
    @report = report
    @contact = contact

    @project_name = if @report.project_id.present?
      @report.project.name(@contact.user)
    else
      @report.project_group.name
    end

    mail(to: @contact.email, subject: "Report Complete: #{@project_name}")

    @report.notifications_sent
  end
end
