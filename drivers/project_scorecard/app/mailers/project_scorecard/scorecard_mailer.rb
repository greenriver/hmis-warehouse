###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectScorecard::ScorecardMailer < ::DatabaseMailer
  def scorecard_prefilled(report, contact)
    @report = report
    @contact = contact

    @project_name = @report.project.ProjectName

    mail(to: @contact.email, subject: "Scorecard For #{@project_name}")
  end

  def scorecard_ready(report, contact)
    @report = report
    @contact = contact

    @project_name = @report.project.ProjectName

    mail(to: @contact.email, subject: "Scorecard For #{@project_name}")
  end
end
