class ProjectDataQualityReportMailer < ApplicationMailer

  def report_complete projects, report, contact
    @projects = projects
    @project_names = @projects.map(&:ProjectName).join(', ')
    @report = report
    @contact = contact
    
    @token = GrdaWarehouse::ReportToken.create(report_id: @report.id, contact_id: @contact.id)
    mail(to: @contact.email, subject: "[Warehouse] Report Complete: #{@project_names}")

    @report.notifications_sent()
  end
end