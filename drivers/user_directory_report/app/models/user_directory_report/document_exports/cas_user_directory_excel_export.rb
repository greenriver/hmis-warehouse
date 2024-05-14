###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module UserDirectoryReport::DocumentExports
  class CasUserDirectoryExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports?
    end

    private def _users(user_model)
      if params[:q].present?
        users = user_model.in_directory.
          text_search(params[:q]).
          order(:last_name, :first_name)
      else
        users = user_model.in_directory.
          order(:last_name, :first_name)
      end
      return users
    end

    protected def view_assigns
      {
        users: _users(CasAccess::User),
        pdf: false,
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
            action: :cas,
            format: :xlsx,
            assigns: view_assigns,
          ),
          "CAS User Directory Report - #{Time.current.to_fs(:db)}",
        ) do |io|
          self.downloadable_file = io
        end
      end
    end

    def downloadable_file=(file_io)
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

    private def controller_class
      UserDirectoryReport::WarehouseReports::UsersController
    end
  end
end
