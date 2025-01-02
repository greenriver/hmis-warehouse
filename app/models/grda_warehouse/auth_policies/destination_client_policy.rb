###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::DestinationClientPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # delegate some methods to source clients
  [
    :can_view,
    :can_view_name,
    :can_view_photo,
    :can_view_full_dob,
    :can_view_full_ssn,
    :can_view_hiv_status,
  ].each do |permission|
    method_name = :"#{permission}?"
    define_method(method_name) do
      client.source_clients.any? do |source_client|
        # Skip sources that are also destinations. This shouldn't be necessary but avoids SystemStackError on bad data
        next if source_client.destination?(strict: true)

        user.policy_for(source_client).send(method_name)
      end
    end
    memoize method_name
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::Hud::Client)
    raise ArgumentError 'Must be a destination client' unless arg.destination?(strict: true)
  end

  def client
    resource
  end
end
