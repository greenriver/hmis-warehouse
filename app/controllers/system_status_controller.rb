###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class SystemStatusController < ApplicationController
  skip_before_action :authenticate_user!

  # Provide a path for nagios or other system checker to determine if the system is
  # operational
  def operational
    user_count = User.all.count
    data_source_count = GrdaWarehouse::DataSource.count
    patient_count = Health::Patient.count
    if user_count.present? && data_source_count.present? && patient_count.present?
      render plain: 'OK'
    else
      render status: 500, plain: 'FAIL'
    end
  end

  def cache_status
    set_value = SecureRandom.hex(10)
    Rails.cache.write('cache-test', set_value)
    pulled_value = Rails.cache.read('cache-test')

    if set_value == pulled_value
      render plain: 'OK'
    else
      render status: 500, plain: 'FAIL'
    end
  end

  def details
    set_value = SecureRandom.hex(10)
    Rails.cache.write('cache-test', set_value)
    pulled_value = Rails.cache.read('cache-test')

    revision = \
      begin
        File.read(Rails.root.join('REVISION'))
      rescue Errno::ENOENT
        'unknown'
      end

    payload = {
      user_count_positive: User.all.any?,
      data_source_count_positive: GrdaWarehouse::DataSource.any?,
      patient_count_positive: Health::Patient.any?,
      revision: revision,
      cache: (set_value == pulled_value ? 'OK' : 'FAILED'),
    }

    render json: payload
  end
end
