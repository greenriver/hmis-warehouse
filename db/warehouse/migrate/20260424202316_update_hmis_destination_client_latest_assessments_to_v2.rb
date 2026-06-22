###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Adds data_source_id to hmis_destination_client_latest_assessments
class UpdateHmisDestinationClientLatestAssessmentsToV2 < ActiveRecord::Migration[7.2]
  # Re-create the "no_modify" trigger originally added in StandardizeIdsToBigint
  # (20260207120000). scenic's update_view drops and re-creates the view, which
  # cascades away any triggers attached to it.
  TRIGGER_NAME = 'no_modify_hmis_destination_client_latest_assessments'
  VIEW_NAME = 'hmis_destination_client_latest_assessments'

  def up
    update_view :hmis_destination_client_latest_assessments, version: 2, revert_to_version: 1
    safety_assured do
      execute(<<~SQL)
        CREATE TRIGGER #{TRIGGER_NAME}
          INSTEAD OF UPDATE OR DELETE ON public."#{VIEW_NAME}"
          FOR EACH ROW EXECUTE FUNCTION prevent_modification();
      SQL
    end
  end

  def down
    update_view :hmis_destination_client_latest_assessments, version: 1, revert_to_version: 2
    safety_assured do
      execute(<<~SQL)
        CREATE TRIGGER #{TRIGGER_NAME}
          INSTEAD OF UPDATE OR DELETE ON public."#{VIEW_NAME}"
          FOR EACH ROW EXECUTE FUNCTION prevent_modification();
      SQL
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260424202316
# rails db:migrate:down:warehouse VERSION=20260424202316
