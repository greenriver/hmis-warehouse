###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PcpSignatureRequestsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    include HealthCareplan
    helper ChaHelper

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_signature_request, only: [:edit, :destroy, :update]
    before_action :set_available_team_members, only: [:new, :create]

    def new
      @signature_request = signature_source.new
      @form_url = polymorphic_path(careplan_path_generator + [:pcp_signature_requests], client_id: @client.id, careplan_id: @careplan.id)
    end

    def edit
    end

    def update
    end

    def create
      @signature_request = signature_source.new
      @form_url = polymorphic_path(careplan_path_generator + [:pcp_signature_requests], client_id: @client.id, careplan_id: @careplan.id)
      begin
        @team_member = team_member_scope.find(signature_params[:team_member_id].to_i)
      rescue ActiveRecord::RecordNotFound
        @signature_request.errors.add(:team_member_id, 'Unable to assign PCP')
        render(:new)
        return
      end
      @expires_at = Time.now + signature_source.expires_in

      @signature_request.assign_attributes(
        patient_id: @patient.id,
        careplan_id: @careplan.id,
        to_email: @team_member.email,
        to_name: @team_member.full_name,
        requestor_email: current_user.email,
        requestor_name: current_user.name,
        expires_at: @expires_at,
      )

      if @signature_request.valid?
        @signature_request.save!
        @careplan.update(
          provider_id: @team_member.id, # Set the careplan provider to the signer
          provider_signature_requested_at: Time.current,
        )
        create_signable_document
        queue_pcp_email
        # TODO: view button to delete request
        respond_with(@signature_request, location: polymorphic_path(careplans_path_generator, client_id: @client.id))
      else
        render(:new)
        nil
      end
    end

    def create_signable_document
      @signers = []
      @signers << { 'email': @signature_request.to_email, 'name': @signature_request.to_name }

      @doc = @careplan.signable_documents.build(
        signers: @signers,
        primary: true,
        user_id: current_user.id,
        expires_at: @expires_at,
      )
      @doc.pdf_content_to_upload = generate_pdf
      if @doc.valid?
        @careplan.class.transaction do
          @doc.save!
          @signature_request.update(signable_document_id: @doc.id)
          @careplan.signable_documents.where.not(id: @doc.id).update_all(primary: false)
          @doc.make_document_signable!
        end

        flash[:notice] = "Created a document (#{@doc.id}) for #{@doc.signers.map(&:email).join('; ')} to sign"
      else
        flash[:error] = @doc.errors.full_messages.join('. ')
      end
    end

    def queue_pcp_email
      HelloSignMailer.pcp_signature_request(
        doc_id: @doc.id,
        email: @signature_request.to_email,
        name: @signature_request.to_name,
        careplan_id: @careplan.id,
        client_id: @client.id,
      ).deliver_later
      @signature_request.update(sent_at: Time.now)
    end

    def destroy
      @signature_request.destroy
      if (signable_document = @signature_request.signable_document)
        signable_document.destroy
      end
      respond_with(@signature_request, location: polymorphic_path(careplans_path_generator, client_id: @client.id))
    end

    def signature_params
      params.require(:signature_request).permit(
        :team_member_id,
        :to_email,
        :to_name,
      )
    end

    def set_available_team_members
      @available_team_members = team_member_scope.
        map do |t|
          [
            "#{t.full_name} -- #{t.class.member_type_name} (#{t.email}) ",
            t.id,
          ]
        end
    end

    def team_member_scope
      @patient.team_members.with_email # .health_sendable # This has been moved to the add team member screen
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

    private

    def generate_pdf
      pdf = careplan_combine_pdf_object
      @pdf = pdf.to_pdf
    end
  end
end
