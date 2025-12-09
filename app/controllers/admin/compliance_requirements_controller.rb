###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class ComplianceRequirementsController < ApplicationController
    skip_before_action :require_compliance_agreement!, raise: false
    before_action :require_can_manage_config!
    before_action :set_requirement, only: [:edit, :update, :destroy, :activate, :deactivate]

    def index
      @requirements = requirement_scope.ordered.includes(:content_page)
      @pagy, @requirements = pagy(@requirements)
    end

    def new
      @requirement = requirement_scope.new
    end

    def create
      @requirement = requirement_scope.new(requirement_params)

      if @requirement.save
        redirect_to admin_compliance_requirements_path, notice: 'Compliance requirement created.'
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @requirement.update(requirement_params)
        redirect_to admin_compliance_requirements_path, notice: 'Compliance requirement updated.'
      else
        render :edit
      end
    end

    def destroy
      if @requirement.agreements.exists?
        redirect_to admin_compliance_requirements_path, alert: 'Cannot delete requirement with existing agreements. Deactivate instead.'
      else
        @requirement.destroy
        redirect_to admin_compliance_requirements_path, notice: 'Compliance requirement deleted.'
      end
    end

    def activate
      @requirement.update!(active: true)
      redirect_to admin_compliance_requirements_path, notice: "#{@requirement.name} activated."
    end

    def deactivate
      @requirement.update!(active: false)
      redirect_to admin_compliance_requirements_path, notice: "#{@requirement.name} deactivated."
    end

    private

    def requirement_scope
      GrdaWarehouse::Compliance::Requirement.all
    end

    def set_requirement
      @requirement = requirement_scope.find(params[:id])
    end

    def requirement_params
      params.
        require(:compliance_requirement).
        permit(:name, :content_page_id, :expires_after_days, :revision, :position)
    end
  end
end
