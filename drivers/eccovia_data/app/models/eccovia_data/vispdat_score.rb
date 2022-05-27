###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class EccoviaData::VispdatScore < GrdaWarehouse::RemoteConfig
  def get
    remote_credential.get_all(vispdat_query)
  end

  private def vispdat_query
    'crql?q=SELECT ScoreTotal FROM VISPDAT'
  end
end
