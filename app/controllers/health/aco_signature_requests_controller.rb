###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class AcoSignatureRequestsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthCareplan
    helper ChaHelper

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_signature_request, only: [:edit, :destroy, :update, :download_careplan]
    before_action :set_signable_document, only: [:edit, :update, :download_careplan]
    before_action :set_available_team_members, only: [:new, :create]
    before_action :require_matching_hash!, only: [:edit, :update, :download_careplan]
    before_action :require_doc_not_expired!, only: [:update, :download_careplan]
    before_action :set_form_url, only: [:edit, :update]
    before_action :set_careplan_download_url, only: [:edit, :update]

    # This supports signing without logging in:
    skip_before_action :authenticate_user!, only: [:edit, :update, :download_careplan]
    skip_before_action :require_some_patient_access!, only: [:edit, :update, :download_careplan]

    def new
      @signature_request = signature_source.new
      @form_url = polymorphic_path(careplan_path_generator + [:aco_signature_requests], client_id: @client.id, careplan_id: @careplan.id)
    end

    def edit
      @state = :valid
      @state = :expired if @doc.expired?
      @form_url = polymorphic_path(careplan_path_generator + [:aco_signature_request], client_id: @client.id, careplan_id: @careplan.id, id: @signature_request.id, email: params[:email], hash: params[:hash])
      @careplan_link = download_careplan_client_health_careplan_aco_signature_request_path(client_id: @client.id, careplan_id: @careplan.id, id: @signature_request.id, email: params[:email], hash: params[:hash])
    end

    def download_careplan
      pdf = careplan_combine_pdf_object
      file_name = 'care_plan'
      send_data pdf.to_pdf, filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    # Build and send a PCP signing request and team member based on the values submitted
    #
    def update
      @signature_request.errors.add(:to_name, 'PCP Name is required') if signature_params[:to_name].blank?
      @signature_request.errors.add(:to_email, 'PCP email must belong to a known agency. See list at the bottom of the page') if signature_params[:to_email].blank? || ! Health::Agency.email_valid?(signature_params[:to_email])
      if @signature_request.errors.any?
        @state = :valid # force the form to show again
        render(:edit)
        return
      end
      (first_name, last_name) = signature_params[:to_name].split(' ')
      email = signature_params[:to_email]
      team_member = Health::Team::Provider.new(
        first_name: first_name,
        last_name: last_name,
        email: email,
        organization: 'Unknown',
        patient_id: @patient.id,
        user_id: User.setup_system_user.id,
      )
      team_member.save(validate: false)

      @pcp_signature_request = pcp_signature_source.new
      @expires_at = Time.now + pcp_signature_source.expires_in

      @pcp_signature_request.assign_attributes(
        patient_id: @patient.id,
        careplan_id: @careplan.id,
        to_email: email,
        to_name: signature_params[:to_name],
        requestor_email: @signature_request.to_email,
        requestor_name: @signature_request.to_name,
        expires_at: @expires_at,
      )

      if @pcp_signature_request.valid?
        @pcp_signature_request.save!
        create_pcp_signable_document
        queue_pcp_email
        flash[:notice] = 'Thank you. The Care Plan Signature request will be sent to the PCP.'
      else
        render(:edit)
        nil
      end
    end

    def create_pcp_signable_document
      @signers = []
      @signers << { 'email': @pcp_signature_request.to_email, 'name': @pcp_signature_request.to_name }

      @doc = @careplan.signable_documents.build(
        signers: @signers,
        primary: true,
        user_id: User.setup_system_user.id,
        expires_at: @expires_at,
      )
      @doc.pdf_content_to_upload = generate_pdf
      if @doc.valid?
        @careplan.class.transaction do
          @doc.save!
          @pcp_signature_request.update(signable_document_id: @doc.id)
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
        email: @pcp_signature_request.to_email,
        name: @pcp_signature_request.to_name,
        careplan_id: @careplan.id,
        client_id: @client.id,
      ).deliver_later
      @pcp_signature_request.update(sent_at: Time.now)
    end

    def create
      @signature_request = signature_source.new
      @form_url = polymorphic_path(careplan_path_generator + [:aco_signature_requests], client_id: @client.id, careplan_id: @careplan.id)
      begin
        @team_member = team_member_scope.find(signature_params[:team_member_id].to_i)
      rescue ActiveRecord::RecordNotFound
        @signature_request.errors.add(:team_member_id, 'Unable to assign ACO')
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
        create_signable_document
        queue_aco_email
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

    def queue_aco_email
      HelloSignMailer.aco_signature_request(
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

    def signable_document_source
      Health::SignableDocument
    end

    def set_signable_document
      @doc = @signature_request.signable_document
    end

    def signature_source
      Health::SignatureRequests::AcoSignatureRequest
    end

    def pcp_signature_source
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
      { resource_name: 'ACO Signature Request' }
    end

    private

    def generate_pdf
      pdf = careplan_combine_pdf_object
      @pdf = pdf.to_pdf
    end

    def set_form_url
      @form_url = polymorphic_path(careplan_path_generator + [:aco_signature_request], client_id: @client.id, careplan_id: @careplan.id, id: @signature_request.id, email: params[:email], hash: params[:hash])
    end

    def set_careplan_download_url
      @careplan_link = download_careplan_client_health_careplan_aco_signature_request_path(client_id: @client.id, careplan_id: @careplan.id, id: @signature_request.id, email: params[:email], hash: params[:hash])
    end

    def require_matching_hash!
      return if @doc.signer_hash(params[:email]) == params[:hash]

      not_authorized!
      nil
    end

    def require_doc_not_expired!
      return unless @doc.expired?

      not_authorized!
      nil
    end
  end
end
