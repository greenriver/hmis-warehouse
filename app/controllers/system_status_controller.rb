class SystemStatusController < ApplicationController
  skip_before_action :authenticate_user!

  # Provide a path for nagios or other system checker to determine if the system is 
  # operational
  def operational
    user_count = User.all.count
    data_source_count = GrdaWarehouse::DataSource.count
    patient_count = Health::Patient.count
    if user_count > 0 && data_source_count.present? && patient_count.present?
      render plain: 'OK'
    else
      render status: 500, plain: 'FAIL'
    end
  end
end