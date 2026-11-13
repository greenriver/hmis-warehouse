###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# `file` is CarrierWave's mount column and only ever held a filename. New uploads
# get their name from the ActiveStorage attachment, so stop requiring it. The column
# stays for un-migrated rows and can be dropped with CarrierWave.
class MakeNonHmisUploadsFileNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :non_hmis_uploads, :file, true
  end
end
