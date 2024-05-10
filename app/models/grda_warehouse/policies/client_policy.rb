
#
class GrdaWarehouse::Policies::ClientPolicy
  attr_reader :access_context
  delegate :can_view_full_dob?, :can_view_full_ssn?, :can_view_client_name?, to: :access_context

  def initialize(access_context)
    @access_context = access_context
  end

  def can_view_name?
    access_context.can_view_client_name?
  end
end
