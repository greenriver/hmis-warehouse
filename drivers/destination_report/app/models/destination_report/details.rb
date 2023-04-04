###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  DestinationReport::Details
  extend ActiveSupport::Concern
  included do
    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def detail_hash
      {}.merge(destination_detail_hash)
    end

    def destination_detail_hash
      @destination_detail_hash ||= {}.tap do |hashes|
        data_for_destinations.each do |population, data|
          if population == :all
            data.each do |title, client_ids|
              key = [population, title].join('_').underscore
              hashes[key] = {
                title: "Destination: #{title}",
                headers: client_headers,
                columns: client_columns,
                scope: report_scope.joins(:client).where(client_id: client_ids),
              }
            end
          else
            data.each do |coc_code, coc_data|
              coc_data[:destinations]&.each do |title, client_ids|
                key = [coc_code, title].join('_').underscore
                hashes[key] = {
                  title: "Destination: #{title}",
                  headers: client_headers,
                  columns: client_columns,
                  scope: report_scope.joins(:client).where(client_id: client_ids),
                }
              end
              coc_data[:destination_details]&.each do |title, detail_data|
                detail_data&.each do |sub_title, client_ids|
                  key = [coc_code, title, sub_title].join('_').underscore
                  hashes[key] = {
                    title: "Destination: #{title} - #{sub_title}",
                    headers: client_headers,
                    columns: client_columns,
                    scope: report_scope.joins(:client).where(client_id: client_ids),
                  }
                end
              end
            end
          end
        end
      end
    end

    def detail_scope_from_key(key)
      detail = detail_hash[key]
      return report_scope.none unless detail

      detail[:scope].distinct
    end

    def support_title(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:title]
    end

    def header_for(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:headers]
    end

    def headers_for_export(key)
      headers = header_for(key)
      return headers if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      (headers || []).excluding(['Last Name', 'First Name', 'DOB'])
    end

    def columns_for(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:columns]
    end

    def columns_for_export(key)
      columns = columns_for(key)
      return columns if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      (columns || []).reject { |a| ['FirstName', 'LastName', 'DOB'].include?(a.name) }
    end

    def detail_column_display(header:, column:)
      case header
      when 'Project Type'
        HudUtility.project_type(column)
      when 'CoC'
        HudUtility.coc_name(column)
      when 'Female', 'Male', 'No Single Gender', 'Transgender', 'Questioning', 'Unknown Gender'
        HudUtility.no_yes_reasons_for_missing_data(column)
      when *HudUtility.races.values
        HudUtility.no_yes_missing(column)
      else
        column
      end
    end

    def client_headers
      [
        'Client ID',
        'First Name',
        'Last Name',
        'DOB',
        'Female',
        'Male',
        'No Single Gender',
        'Transgender',
        'Questioning',
        'Unknown Gender',
        'Ethnicity',
      ] + HudUtility.races.values
    end

    def client_columns
      [
        c_t[:id],
        c_t[:FirstName],
        c_t[:LastName],
        c_t[:DOB],
        c_t[:Female],
        c_t[:Male],
        c_t[:NoSingleGender],
        c_t[:Transgender],
        c_t[:Questioning],
        c_t[:GenderNone],
        c_t[:Ethnicity],
      ] + HudUtility.races.keys.map { |k| c_t[k.to_sym] }
    end
  end
end
