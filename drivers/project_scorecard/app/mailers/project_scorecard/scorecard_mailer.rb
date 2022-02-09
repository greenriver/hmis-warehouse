###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectScorecard::ScorecardMailer < ::DatabaseMailer
  def scorecard_prefilled(report, contact)
    @report = report
    @contact = contact

    mail(to: @contact.email, subject: "Scorecard For #{@report.project_name}")
  end

  def scorecard_ready(report, contact)
    @report = report
    @contact = contact

    mail(to: @contact.email, subject: "Scorecard For #{@report.project_name}")
  end

  def scorecard_complete(report)
    @report = report
    @contact = report.user

    mail(to: @contact.email, subject: "Scorecard For #{@report.project_name} Completed")
  end
end
