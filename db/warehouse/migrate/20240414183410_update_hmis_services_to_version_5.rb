#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class UpdateHmisServicesToVersion5 < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      add_column :Services, :enrollment_pk, :bigint
      add_index :Services, :enrollment_pk
      add_foreign_key :Services, :Enrollment, column: :enrollment_pk, name: 'fk_service_enrollment_pk'

      add_column :CustomServices, :enrollment_pk, :bigint
      add_index :CustomServices, :enrollment_pk
      add_foreign_key :Services, :Enrollment, column: :enrollment_pk, name: 'fk_custom_service_enrollment_pk'
    end
    update_view :hmis_services, version: 5
    # now run
    # rails runner driver:hmis:data_migration:update_project_service_pk
  end

  # the scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_services, version: 4
    remove_column :Services, :enrollment_pk
    remove_column :CustomServices, :enrollment_pk
  end
end
