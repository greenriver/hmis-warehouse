# always false
class GrdaWarehouse::AuthPolicies::DenyPolicy
  include Singleton

  Role.permissions.each do |permission|
    define_method :"#{permission}?" do
      false
    end
  end
end
