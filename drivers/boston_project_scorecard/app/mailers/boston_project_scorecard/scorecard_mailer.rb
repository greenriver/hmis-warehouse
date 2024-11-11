###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: the rails mailer does not appear to be aware of drivers; templates are in main view directory
class BostonProjectScorecard::ScorecardMailer < ::DatabaseMailer
  def scorecard_prefilled(report, contact)
    @report = report
    @contact = contact

    mail(to: @contact.email, subject: "Scorecard For #{@report&.project_name || 'unknown'}")
  end

  def scorecard_ready(report)
    @report = report
    @contact = @report.secondary_reviewer

    mail(to: @contact.email, subject: "Scorecard For #{@report&.project_name || 'unknown'}")
  end

  def scorecard_complete(report)
    @report = report
    @contact = report.user

    mail(to: @contact.email, subject: "Scorecard For #{@report&.project_name || 'unknown'} Completed")
  end
end
