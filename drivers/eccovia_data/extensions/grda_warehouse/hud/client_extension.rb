###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EccoviaDatum
  module GrdaWarehouse
    module Hud
      module ClientExtension
        extend ActiveSupport::Concern
        include ArelHelper

        included do
          has_many :eccovia_assessments, class_name: 'EccoviaData::Assessment', foreign_key: [:client_id, :data_source_id], primary_key: [:PersonalID, :data_source_id]
          has_many :source_eccovia_assessments, through: :source_clients, source: :eccovia_assessments

          has_many :eccovia_client_contacts, class_name: 'EccoviaData::ClientContact', foreign_key: [:client_id, :data_source_id], primary_key: [:PersonalID, :data_source_id]
          has_many :source_eccovia_client_contacts, through: :source_clients, source: :eccovia_client_contacts

          has_many :eccovia_case_managers, class_name: 'EccoviaData::CaseManager', foreign_key: [:client_id, :data_source_id], primary_key: [:PersonalID, :data_source_id]
          has_many :source_eccovia_case_managers, through: :source_clients, source: :eccovia_case_managers
        end
      end
    end
  end
end
