class ProjectDataQualityReportMailer < ApplicationMailer

  def report_complete project, report, contact
    @project = project
    @report = report
    @contact = contact
    
    @token = GrdaWarehouse::ReportToken.create(report_id: @report.id, contact_id: @contact.id)
    mail(to: @contact.email, subject: "[Warehouse] Report Complete: #{@project.ProjectName}")

    @report.notifications_sent()
  end
end