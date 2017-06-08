class ProjectDataQualityReportMailer < ApplicationMailer

  def report_complete project, report
    @project = project
    @report = report
    @contacts = @project.project_contacts
    @contacts.each do |contact|
      @token = GrdaWarehouse::ReportToken.create(report_id: @report.id, contact_id: contact.id)
      mail(to: contact.email, subject: '[Warehouse] Report Complete')
    end
    @report.notifications_sent()
  end
end