module EtoApi
  class Detail < Base

    def attribute_name cdid:, site_id:
      site_demographics(site_id: site_id).index_by{|d| d['CDID']}[cdid].try(:[], "Name")
    end

    def attribute_id attribute_name:, site_id:
      site_demographics(site_id: site_id).index_by{|d| d['Name']}[attribute_name].try(:[], 'CDID')
    end

  end
end