###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::DocumentExport < GrdaWarehouseBase
  include DocumentExportBehavior

  def data_url
    document_exports_path
  end

  def download_url
    download_document_export_url(id, host: ENV['FQDN'], protocol: 'https' )
  end

  protected def filter
    @filter ||= begin
      f = ::Filters::FilterBase.new(user_id: user.id)
      filter_params = params['filters'].presence&.deep_symbolize_keys
      f.set_from_params(filter_params) if filter_params

      f
    end
  end

  protected def params
    query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
  end
end
