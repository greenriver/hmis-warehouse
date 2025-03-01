# frozen_string_literal: true

class Filters::Criteria::Base
  attr_accessor :input, :config

  def id = Filters::Criteria::IDS_BY_CLASS.fetch(self.class)
  def arel = Hmis::ArelHelper.instance
  def user = input.user

  def applies?
    true # default to true
  end

  def apply(scope)
    raise 'Apply called on unapplicable criteria' unless applies?

    return scope # default applies no filter
  end

  def initialize(input:, config: nil)
    @input = input
    @config = config || Filters::Criteria::Configuration.new
  end

  def viewable_project_scope
    GrdaWarehouse::Hud::Project.viewable_by(input.user, permission: :can_view_assigned_reports)
  end
end
