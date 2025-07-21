###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :custom_client_addresses, **Hmis::Hud::Base.hmis_relation(:PersonalID, 'CustomClientAddress'), inverse_of: :client
      has_many :custom_client_contact_points, **Hmis::Hud::Base.hmis_relation(:PersonalID, 'CustomClientContactPoint'), inverse_of: :client
      has_many :hmis_custom_assessments, through: :enrollments
      has_many :hmis_source_custom_assessments, through: :source_enrollments, source: :hmis_custom_assessments
      has_many :custom_services, through: :source_enrollments
      has_many :ce_client_proxies, as: :client, class_name: 'Hmis::Ce::ClientProxy', dependent: :destroy
      has_many :ce_match_candidates, class_name: 'Hmis::Ce::Match::Candidate', through: :ce_client_proxies

      # WarehouseClient and Source Client(s) represented as Hmis:: models
      # (Associations defined on GrdaWarehouse::Hud::Client are represented as GrdaWarehouse::WarehouseClient and GrdaWarehouse::Hud::Client respectively)
      has_many :hmis_warehouse_client_destination, class_name: 'Hmis::WarehouseClient', foreign_key: :destination_id
      has_many :hmis_source_clients, -> { hmis }, class_name: 'Hmis::Hud::Client', through: :hmis_warehouse_client_destination, source: :source
      has_one :change_marker, as: :trackable, class_name: 'Hmis::Ce::ChangeMarker', dependent: :destroy, foreign_key: :trackable_id

      def as_hmis
        Hmis::Hud::Client.find(id)
      end

      # Contact information used by the Warehouse Client model
      # to populate the Client Dashboard and CAS
      def most_recent_home_phone_hmis
        custom_client_contact_points.home_phones.with_value.max_by(&:DateUpdated)&.value
      end

      def most_recent_cell_or_other_phone_hmis
        # prefer most recent number that is explicitly marked as mobile, otherwise latest number for other/unknown
        [
          custom_client_contact_points.mobile_phones.with_value.max_by(&:DateUpdated)&.value,
          custom_client_contact_points.other_or_unknown_phones.with_value.max_by(&:DateUpdated)&.value,
        ].compact.first
      end

      def most_recent_work_or_school_phone_hmis
        custom_client_contact_points.work_or_school_phones.max_by(&:DateUpdated)&.value
      end

      def most_recent_email_hmis
        custom_client_contact_points.emails.with_value.max_by(&:DateUpdated)&.value
      end
    end
  end
end
