# frozen_string_literal: true

# Shared helpers for request specs that exercise the SubmitForm mutation.
# Include this in any spec that calls submitForm.
module SubmitFormSpecHelpers
  include GraphqlHelpers

  def submit_form_mutation
    <<~GRAPHQL
      mutation SubmitForm($input: SubmitFormInput!) {
        submitForm(input: $input) {
          record {
            ... on Client {
              id
            }
            ... on Organization {
              id
            }
            ... on Project {
              id
            }
            ... on Funder {
              id
            }
            ... on ProjectCoc {
              id
            }
            ... on Inventory {
              id
            }
            ... on Service {
              id
            }
            ... on File {
              id
            }
            ... on CustomCaseNote {
              id
            }
            ... on Enrollment {
              id
            }
            ... on CurrentLivingSituation {
              id
            }
            ... on CeAssessment {
              id
            }
            ... on Event {
              id
            }
            ... on HmisParticipation {
              id
            }
            ... on CeParticipation {
              id
            }
            ... on ReferralPosting {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  # Posts the SubmitForm mutation and returns [record, errors].
  # Uses mutation, or submit_form_mutation if omitted.
  def submit_form(input, mutation: nil, expect_validation_errors: false, expect_raise: false)
    mutation_str = mutation || submit_form_mutation
    response, result = post_graphql(input: { input: input }) { mutation_str }
    expect(response.status).to eq(200), result&.inspect unless expect_raise
    return response, result if expect_raise # if submission is expected to raise, return the raw response and result

    record = result.dig('data', 'submitForm', 'record')
    errors = result.dig('data', 'submitForm', 'errors')

    unless expect_validation_errors
      expect(errors).to be_empty
      expect(record).to be_present
      expect(record['id']).to eq(input[:record_id].to_s) if input[:record_id].present?
    end

    [record, errors]
  end
end
