###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# stateless collection of functions for creating CSV files ingested by Tableau
require 'zip'
module Exporters::Tableau
  include ArelHelper
  include TableauExport

  module_function

  # adjust to take report_id optionally
  def export_all(path: 'var/exports/tableau', start_date: default_start, end_date: default_end, coc_code: nil, report_id:)
    path = "#{path}/#{report_id}" if report_id
    FileUtils.mkdir_p path unless Dir.exist? path
    available_exports.each do |file_name, klass|
      file_path = File.join(path, file_name.to_s)
      file_path += '.csv'
      Rails.logger.info "Exporting #{file_path}"
      klass.to_csv(start_date: start_date, end_date: end_date, coc_code: coc_code, path: file_path)
    end
    return unless report_id

    zip_report_folder(path: path, report_id: report_id)
    add_zip_to_report(path: path, report_id: report_id)
    GrdaWarehouse::DashboardExportReport.find(report_id).update(completed_at: Time.now)
    remove_path(path: path)
  end

  def zip_path(path:, report_id:)
    File.join(path, "#{report_id}.zip")
  end

  def zip_report_folder(path:, report_id:)
    files = Dir.glob(File.join(path, '*')).map { |f| File.basename(f) }
    Zip::File.open(zip_path(path: path, report_id: report_id), Zip::File::CREATE) do |zipfile|
      files.each do |file_name|
        zipfile.add(
          file_name,
          File.join(path, file_name),
        )
      end
    end
  end

  def add_zip_to_report(path:, report_id:)
    report = GrdaWarehouse::DashboardExportReport.find(report_id)
    report_file = GrdaWarehouse::DashboardExportFile.new(user_id: report.user_id)
    file = Pathname.new(zip_path(path: path, report_id: report_id)).open
    report_file.content = file.read
    report_file.content_type = 'application/zip'
    report_file.save!
    report.file_id = report_file.id
    report.save!
  end

  def remove_path(path:)
    FileUtils.rmtree(path)
  end

  def available_exports
    {
      disability: Exporters::Tableau::Disability,
      income: Exporters::Tableau::Income,
      entryexit: Exporters::Tableau::EntryExit,
      pathways: Exporters::Tableau::Pathways,
      pathways_with_dest: Exporters::Tableau::PathwaysWithDest,
      vispdat: Exporters::Tableau::Vispdat,
    }
  end
end
