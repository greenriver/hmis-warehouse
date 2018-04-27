# stateless collection of functions for creating CSV files ingested by Tableau
module Exporters::Tableau
  include ArelHelper
  include TableauExport

  module_function
    def export_all path: 'var/exports/tableau', start_date: default_start, end_date: default_end, coc_code: nil
      FileUtils.mkdir_p path unless Dir.exists? path
      available_exports.each do |file_name, klass|
        file_path = File.join(path, file_name.to_s)
        file_path += '.csv'
        klass.to_csv(start_date: start_date, end_date: end_date, coc_code: coc_code, path: file_path)
      end
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