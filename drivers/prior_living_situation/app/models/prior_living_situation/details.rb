###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  PriorLivingSituation::Details
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
      {}.merge(living_situation_detail_hash)
    end

    def living_situation_detail_hash
      @living_situation_detail_hash ||= {}.tap do |hashes|
        data_for_living_situations.each do |population, data|
          if population == :all
            data.each do |title, client_ids|
              key = [population, title].join('_').underscore
              hashes[key] = {
                title: "Prior Living Situation: #{title}",
                headers: client_headers,
                columns: client_columns,
                scope: report_scope.joins(:client).where(client_id: client_ids),
              }
            end
          else
            data.each do |coc_code, coc_data|
              coc_data[:situations]&.each do |title, client_ids|
                key = [coc_code, title].join('_').underscore
                hashes[key] = {
                  title: "Prior Living Situation: #{title}",
                  headers: client_headers,
                  columns: client_columns,
                  scope: report_scope.joins(:client).where(client_id: client_ids),
                }
              end
              coc_data[:situations_length]&.each do |title, detail_data|
                detail_data&.each do |sub_title, client_ids|
                  key = [coc_code, title, sub_title].join('_').underscore
                  hashes[key] = {
                    title: "Prior Living Situation: #{title} - #{sub_title}",
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

    def columns_for(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:columns]
    end

    def headers_for_export(key)
      return header_for(key) if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      (header_for(key) || []).reject { |s| ['First Name', 'Last Name', 'DOB'].include?(s) }
    end

    def columns_for_export(key)
      return columns_for(key) if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      (columns_for(key) || []).reject { |a| ['FirstName', 'LastName', 'DOB'].include?(a.name) }
    end

    def detail_column_display(header:, column:)
      case header
      when 'Project Type'
        HudUtility2024.project_type(column)
      when 'CoC'
        HudUtility2024.coc_name(column)
      when 'Woman', 'Man', 'Culturally Specific', 'Different Identity', 'Non-Binary', 'Transgender', 'Questioning', 'Unknown Gender'
        HudUtility2024.no_yes_reasons_for_missing_data(column)
      when *HudUtility2024.races.values
        HudUtility2024.no_yes_missing(column)
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
        'Woman',
        'Man',
        'Culturally Specific',
        'Different Identity',
        'Non-Binary',
        'Transgender',
        'Questioning',
        'Unknown Gender',
      ] + HudUtility2024.races.values
    end

    def client_columns
      [
        c_t[:id],
        c_t[:FirstName],
        c_t[:LastName],
        c_t[:DOB],
        c_t[:Woman],
        c_t[:Man],
        c_t[:NonBinary],
        c_t[:Transgender],
        c_t[:Questioning],
        c_t[:GenderNone],
      ] + HudUtility2024.races.keys.map { |k| c_t[k.to_sym] }
    end
  end
end
