###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddHmisCsvRemapKeyFunction < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      execute <<~SQL
        CREATE OR REPLACE FUNCTION hmis_csv_remap_key(column_name text, source_id text, original text)
        RETURNS text AS $$
        BEGIN
          RETURN md5(column_name || '--' || source_id || '--' || original);
        END;
        $$ LANGUAGE plpgsql IMMUTABLE;
      SQL
    end
  end

  def down
    safety_assured do
      execute 'DROP FUNCTION IF EXISTS hmis_csv_remap_key(text, text, text);'
    end
  end
end
