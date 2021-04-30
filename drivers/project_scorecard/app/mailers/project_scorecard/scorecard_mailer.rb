###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectScorecard::ScorecardMailer < ::DatabaseMailer
  def scorecard_prefilled(report, contact)
    @report = report
    @contact = contact

    @project_name = if @report.project.present?
      @report.project.ProjectName
    else
      @report.project_group.name
    end

    mail(to: @contact.email, subject: "Scorecard For #{@project_name}")
  end

  def scorecard_ready(report, contact)
    @report = report
    @contact = contact

    @project_name = if @report.project.present?
      @report.project.ProjectName
    else
      @report.project_group.name
    end

    mail(to: @contact.email, subject: "Scorecard For #{@project_name}")
  end

  def scorecard_complete(report)
    @report = report
    @contact = report.user

    @project_name = if @report.project.present?
      @report.project.ProjectName
    else
      @report.project_group.name
    end

    mail(to: @contact.email, subject: "Scorecard For #{@project_name} Completed")
  end
end
