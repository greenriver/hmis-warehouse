module Reports::CAPER::Fy2017
  class Base < Report
    def self.report_name
      'CAPER - FY 2017'
    end

    def self.generator
      ReportGenerators::CAPER::Fy2017::Base
    end

    def self.available_projects
      GrdaWarehouse::Hud::Project.joins(:data_source).
        merge(GrdaWarehouse::DataSource.order(:short_name)).
        order(:ProjectName).
        pluck(:ProjectName, :id, :short_name).
        map do |name, id, short_name|
          ["#{name} - #{short_name}", id]
        end
    end

    def self.available_project_types
      HUD::project_types.invert
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable.pluck(:short_name, :id)
    end

    def download_type
      :xml
    end

    def report_type
      0
    end

    def has_custom_form?
      true
    end
    
    def has_options?
      true
    end

    # all of the subclasses of this base will have the same partial (unless they override this)
    # this is based off of ActiveModel::Conversion::ClassMethods._to_partial_path, which is the default
    def self._to_partial_path
      @_to_partial_path ||= self.name.downcase.gsub( '::', '/' ).sub /\w+$/, 'base'
    end

    def title_for_options
      'CoC Code'
    end

    def self.available_options
      [
        :report_start,
        :report_end,
        :coc_code,
        :coc_zip_codes,
        :oct_night,
        :jan_night,
        :apr_night,
        :jul_night,
        :continuum_name,
      ]
    end

    def value_for_options options
      options['coc_code']
    end

    def continuum_name
      @continuum_name ||= GrdaWarehouse::Config.get(:continuum_name)
    end

    def as_xml report_results
      raise NotImplementedError
      
      user = report_results.user
      completed_date = report_results.completed_at.to_date.strftime("%Y-%m-%d") 
      results = report_results.results
      coc_name = report_results.options.try(:[], 'continuum_name') || continuum_name()
      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.AHARReport('xmlns' => 'http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd http://www.hudhdx.info/Resources/Vendors/ahar/2_0_3/HUD_HMIS_AHAR_2_0_3.xsd') do
          xml.ContactName "#{user.first_name} #{user.last_name}"
          xml.ContinuumName coc_name
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
