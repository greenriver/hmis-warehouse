###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Ahar::Fy2016
  class Base < Report
    def self.report_name
      'AHAR - FY 2016'
    end

    def report_group_name
      'Annual Homeless Assessment Report'
    end

    def self.available_projects_for_filtering
      GrdaWarehouse::Hud::Project.joins(:data_source).merge(GrdaWarehouse::DataSource.order(:short_name)).order(:ProjectName).pluck(:ProjectName, :ProjectID, :data_source_id, :short_name).map do |name,id,ds_id,short_name|
        ["#{name} - #{short_name}", [id,ds_id]]
      end
    end

    def self.available_data_sources_for_filtering
      GrdaWarehouse::DataSource.importable.pluck(:short_name, :id)
    end

    def download_type
      :xml
    end

    def report_type
      0
    end

    def continuum_name
      'Boston Continuum of Care'
    end

    def as_xml report_results
      user = report_results.user
      completed_date = report_results.completed_at.to_date.strftime("%Y-%m-%d")
      results = report_results.results
      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.AHARReport('xmlns' => 'http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd') do
          xml.ContactName "#{user.first_name} #{user.last_name}"
          xml.ContinuumName continuum_name
          xml.DateCompleted completed_date
          xml.ReportYear 2016
          xml.ReportType report_type

          xml.Category do
            results.each do |k,section|
              xml.send(k) do
                section.each do |label,value|
                  xml.send(label, value)
                end
              end
            end
          end
        end
        #(AHARReport: {xmlns: 'http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd'})
      end.to_xml
    end
  end
end
