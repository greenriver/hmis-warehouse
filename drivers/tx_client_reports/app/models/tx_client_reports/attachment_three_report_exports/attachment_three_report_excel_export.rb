###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports::AttachmentThreeReportExports
  class AttachmentThreeReportExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper

    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(filter)
    end

    protected def view_assigns
      {
        report: report,
        filter: filter,
      }
    end

    def perform
      with_status_progression do
        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        warden_proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
          i.set_user(user, scope: :user, store: false, run_callbacks: false)
        end

        renderer = controller_class.renderer.new(
          'warden' => warden_proxy,
        )

        write_tmp_file(
          renderer.render(
            action: :index,
            format: :xlsx,
            assigns: view_assigns,
          ),
          "Attachment III - Client Data #{Time.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def pdf_file=(file_io)
      self.filename = File.basename(file_io.path)
      self.file_data = file_io.read
      self.mime_type = EXCEL_MIME_TYPE
    end

    private def write_tmp_file(data, file_name)
      Dir.mktmpdir do |dir|
        safe_name = file_name.gsub(/[^- a-z0-9]+/i, ' ').slice(0, 50).strip
        file_path = "#{dir}/#{safe_name}.xlsx"
        File.open(file_path, 'wb') { |file| file.write(data) }
        yield(Pathname.new(file_path).open)
      end
      true
    end

    protected def report_class
      TxClientReports::AttachmentThreeReport
    end

    private def controller_class
      TxClientReports::WarehouseReports::AttachmentThreeClientDataReportsController
    end
  end
end