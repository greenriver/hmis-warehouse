###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHmisRestrictedClientEnrollments < ActiveRecord::Migration[7.2]
  def up
    create_view :hmis_restricted_client_enrollments, version: 1
  end

  def down
    drop_view :hmis_restricted_client_enrollments
  end
end
# rails db:migrate:up:warehouse VERSION=20260805120000
# rails db:migrate:down:warehouse VERSION=20260805120000
