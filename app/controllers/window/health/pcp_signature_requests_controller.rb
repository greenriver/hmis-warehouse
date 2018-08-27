module Window::Health
  class PcpSignatureRequestsController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_signature_request, only: [:edit, :destroy, :update]
    before_action :set_available_team_members, only: [:new, :create]

    include PjaxModalController
    include WindowClientPathGenerator
    def new
      @signature_request = signature_source.new
      @form_url = polymorphic_path(careplan_path_generator + [:pcp_signature_requests], {client_id: @client.id, careplan_id: @careplan.id})
    end

    def edit

    end

    def update

    end

    def create
      @signature_request = signature_source.new
      @form_url = polymorphic_path(careplan_path_generator + [:pcp_signature_requests], {client_id: @client.id, careplan_id: @careplan.id})
      begin
        @team_member = team_member_scope.find(signature_params[:team_member_id].to_i)
      rescue ActiveRecord::RecordNotFound => e
        @signature_request.errors.add(:team_member_id, 'Unable to assign PCP')
        render :new and return
      end
      expires_at = Time.now + signature_source.expires_in

      @signature_request.assign_attributes(
        patient_id: @patient.id,
        careplan_id: @careplan.id,
        to_email: @team_member.email,
        to_name: @team_member.full_name,
        requestor_email: current_user.email,
        requestor_name: current_user.name,
        expires_at: expires_at
      )
      if @signature_request.valid?
        @signature_request.save!
        # TODO create signable document
        # TODO queue email to PCP
        # TODO view button to delete request
        respond_with(@signature_request, location: polymorphic_path(careplans_path_generator, client_id: @client.id))
      else
        render :new and return
      end
    end

    def destroy

    end

    def signature_params
      params.require(:signature_request).permit(
        :team_member_id,
        :to_email,
        :to_name
      )
    end

    def set_available_team_members
      @available_team_members = team_member_scope.
        map do |t|
          [
            "#{t.full_name} -- #{t.class.member_type_name} (#{t.email}) ",
            t.id
          ]
        end
    end

    def team_member_scope
      @patient.team_members.with_email.health_sendable
    end

    def signature_source
      Health::SignatureRequests::PcpSignatureRequest
    end

    def set_signature_request
      @signature_request = signature_source.find(params[:id].to_i)
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end

    def flash_interpolation_options
      { resource_name: 'PCP Signature Request' }
    end
  end
end