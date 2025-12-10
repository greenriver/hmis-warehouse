###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Handles user agreement to compliance requirements (e.g. Terms of Service).
# Users are blocked from accessing the site until all active requirements are agreed to.
#
# @see docs/features/compliance-requirements.md
class ComplianceAgreementsController < ApplicationController
  skip_before_action :require_compliance_agreement!, raise: false

  def show
    @pending_requirements = current_user.pending_compliance_requirements.includes(:content_page)
    return redirect_to root_path if @pending_requirements.empty?

    @current_requirement = @pending_requirements.first
    @content_page = @current_requirement.content_page
  end

  def create
    requirement = GrdaWarehouse::Compliance::Requirement.active.find(params[:requirement_id])
    if params[:revision].to_i != requirement.revision
      redirect_to compliance_agreement_path, alert: 'This requirement was updated. Please review the latest version.'
      return
    end

    if params[:agree] == '1'
      record_agreement(requirement)
      redirect_after_agreement
    else
      flash.now[:alert] = 'You must agree to continue.'
      @pending_requirements = current_user.pending_compliance_requirements.includes(:content_page)
      @current_requirement = requirement
      @content_page = requirement.content_page
      render :show
    end
  end

  private

  def access_captured_for_setup? = true

  def record_agreement(requirement)
    now = Time.current
    expires_at = requirement.expires_after_days ? now + requirement.expires_after_days.days : nil

    current_user.compliance_agreements.create!(
      agreed_at: now,
      compliance_requirement_id: requirement.id,
      revision: requirement.revision,
      expires_at: expires_at,
    )
  end

  def redirect_after_agreement
    remaining = current_user.pending_compliance_requirements
    if remaining.any?
      redirect_to compliance_agreement_path, notice: 'Agreement recorded. Please review the next requirement.'
    else
      path = current_user.my_root_path || root_path
      redirect_to path, notice: 'Agreement recorded.'
    end
  end
end
