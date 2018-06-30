module Admin::Health
  class AccountableCareOrganizationsController < HealthController
    before_action :require_has_administartive_access_to_health!
    before_action :require_can_manage_accountable_care_organizations!
    before_action :set_accountable_care_organization, only: [:edit, :update]

    respond_to :html

    def index
      @accountable_care_organizations = accountable_care_organization_scope.order(name: :asc)
      respond_with(@accountable_care_organizations)
    end

    def new
      @form_url = admin_health_accountable_care_organizations_path
      @accountable_care_organization = accountable_care_organization_source.new
      respond_with(@accountable_care_organizations)
    end

    def edit
      @form_url = admin_health_accountable_care_organization_path
    end

    def create
      @form_url = admin_health_accountable_care_organizations_path
      @accountable_care_organization = accountable_care_organization_source.new(accountable_care_organization_params)
      @accountable_care_organization.save
      respond_with(@accountable_care_organization, location: admin_health_accountable_care_organizations_path)
    end

    def update
      @form_url = admin_health_accountable_care_organization_path
      @accountable_care_organization.update(accountable_care_organization_params)
      respond_with(@accountable_care_organization, location: admin_health_accountable_care_organizations_path)
    end

    private
      def flash_interpolation_options
        { resource_name: 'Accountable Care Organization' }
      end

      def accountable_care_organization_source
        Health::AccountableCareOrganization
      end

      def accountable_care_organization_scope
        accountable_care_organization_source.all
      end

      def set_accountable_care_organization
        @accountable_care_organization = accountable_care_organization_scope.find(params[:id].to_i)
      end

      def accountable_care_organization_params
        params.require(:health_accountable_care_organization).permit(:name, :short_name, :mco_pid, :mco_sl)
      end
  end
end
