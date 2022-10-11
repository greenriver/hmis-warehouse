###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonServices
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_services_rows
    belongs_to :import_file

    has_one :project, through: :enrollment

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:personal_id, :data_source_id], optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: [:EnrollmentID, :data_source_id], foreign_key: [:enrollment_id, :data_source_id], optional: true
    has_one :service, -> do
      where(source_type: 'CustomImportsBostonServices::Row')
    end, class_name: 'GrdaWarehouse::Generic::Service', primary_key: :id, foreign_key: :source_id

    scope :event_eligible, -> do
      ors = CustomImportsBostonServices::Synthetic::Event::EVENT_LOOKUP.keys.map do |service_name, service_item|
        arel_table[:service_name].eq(service_name).and(arel_table[:service_item].eq(service_item))
      end.reduce(&:or)
      where(ors)
    end
  end
end
