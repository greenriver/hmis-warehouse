class GrdaWarehouse::AuthPolicies::AnyPolicy
  attr_reader :policies

  def initialize(policies:)
    @policies = policies
  end

  Role.permissions.each do |permission|
    method_name = :"#{permission}?"
    define_method method_name do
      @policies.any? { |policy| policy.public_send(method_name) }
    end
  end
end
