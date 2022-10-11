###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DefaultFileTypes
  extend ActiveSupport::Concern
  class_methods do
    def default_document_types
      [
        {
          name: 'Birth Certificate',
          group: 'Citizenship Verification',
          included_info: 'DoB, citizenship',
          weight: 0,
        },
        {
          name: 'Social Security Card',
          group: 'Citizenship Verification',
          included_info: 'SSN',
          weight: 1,
        },
        {
          name: 'Green Card',
          group: 'Citizenship Verification',
          included_info: 'SSN',
          weight: 2,
        },
        {
          name: 'State ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
          weight: 3,
        },
        {
          name: 'Passport',
          group: 'Photo ID',
          included_info: 'DoB, citizenship',
          weight: 4,
        },
        {
          name: 'VA ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
          weight: 5,
        },
        {
          name: 'Federal Government ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
          weight: 6,
        },
        {
          name: 'Shelter ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
          weight: 7,
        },
        {
          name: 'HAN Release',
          group: 'Release of Information',
          included_info: 'Network Data Sharing Release',
          weight: 8,
        },
        {
          name: 'Limited CAS Release',
          group: 'Release of Information',
          included_info: 'Verification of interest in housing',
          weight: 9,
        },
        {
          name: 'CoC CORI Release',
          group: 'Release of Information',
          included_info: 'CoC CORI Release',
          weight: 10,
        },
        {
          name: 'DD 214',
          group: 'Veteran Status Verification',
          included_info: 'Vets Status, DoB, SSN',
          weight: 11,
        },
        {
          name: 'Letter of Service',
          group: 'Veteran Status Verification',
          included_info: 'Vets Status',
          weight: 12,
        },
        {
          name: 'Verification of Disability',
          group: 'Disability Verification',
          included_info: 'Verification of Disability',
          note: 'This verification form certifies ONLY that you have the appropriate medical document and certifications on file at your agency for this Client.  This verification should not include any reference whatsoever regarding the actual disability type or reason for disability for a client. ',
          weight: 13,
        },
        {
          name: 'Homeless Verification',
          group: 'Homeless Verification',
          included_info: '',
          weight: 14,
          verified_homeless_history: true,
        },
        {
          name: 'Verification of Program Enrollment for CAS',
          group: 'Homeless Verification',
          included_info: 'Verification of Program Enrollment for CAS',
          weight: 15,
        },
        {
          name: 'Pay Stubs',
          group: 'Income Verification',
          included_info: 'Verification of Income',
          weight: 16,
        },
        {
          name: 'SSDI Printout',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 17,
        },
        {
          name: 'SSI Printout',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 18,
        },
        {
          name: 'SSDI Check',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 19,
        },
        {
          name: 'SSI Check',
          group: 'Income Verification',
          included_info: 'Verification of Income',
          weight: 20,
        },
        {
          name: 'SSA Retirement',
          group: 'Income Verification',
          included_info: 'Verification of Income',
          weight: 21,
        },
        {
          name: 'VA Benefit Letter',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 22,
        },
        {
          name: 'VA Benefit Check',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 23,
        },
        {
          name: 'EAEDC Printout',
          group: 'Income Verification',
          included_info: 'Verification of Income',
          weight: 24,
        },
        {
          name: 'SSP Printout',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 25,
        },
        {
          name: 'SS Survivor Benefit Check',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 26,
        },
        {
          name: 'Alimony Receipt',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 27,
        },
        {
          name: 'Chapter 115 Statement ',
          group: 'Income Verification',
          included_info: 'Verification of Income, Verification of Disability',
          weight: 28,
        },
        {
          name: 'BHA CAS Referral',
          group: 'BHA',
          included_info: 'BHA CAS Referral',
          weight: 29,
        },
        {
          name: 'BHA CORI Request',
          group: 'BHA',
          included_info: 'BHA CORI Request',
          weight: 30,
        },
        {
          name: 'BHA Application',
          group: 'BHA',
          included_info: 'BHA Application',
          weight: 31,
        },
        {
          name: 'Other',
          group: 'Other',
          note: 'Please specify contents under note',
          weight: 32,
        },
      ]
    end

    def original_default_document_types
      [
        {
          name: 'Birth Certificate',
          group: 'Document Type',
          weight: 0,
          document_ready: true,
        },
        {
          name: 'Government ID',
          group: 'Document Type',
          weight: 1,
          document_ready: true,
        },
        {
          name: 'Social Security Card',
          group: 'Document Type',
          weight: 2,
          document_ready: true,
        },
        {
          name: 'Disability Verification',
          group: 'Document Type',
          weight: 3,
          note: 'This verification form certifies ONLY that you have the appropriate medical document and certifications on file at your agency for this Client.  This verification should not include any reference whatsoever regarding the actual disability type or reason for disability for a client. ',
        },
        {
          name: 'Homeless Verification',
          group: 'Document Type',
          weight: 4,
        },
        {
          name: 'Veteran Verification',
          group: 'Document Type',
          weight: 5,
        },
        {
          name: 'Proof of Income',
          group: 'Document Type',
          weight: 6,
        },
        {
          name: 'Client Photo',
          group: 'Document Type',
          weight: 7,
        },
        {
          name: 'DD-214',
          group: 'Document Type',
          weight: 8,
          document_ready: true,
        },
        {
          name: 'Consent Form',
          group: 'Document Type',
          weight: 9,
          notification_trigger: true,
        },
        {
          name: 'Full Network Release',
          group: 'Document Type',
          weight: 10,
        },
        {
          name: 'Limited CAS Release',
          group: 'Document Type',
          weight: 11,
        },
        {
          name: 'Chronic Homelessness Verification',
          group: 'Document Type',
          weight: 12,
          document_ready: true,
        },
        {
          name: 'BHA Eligibility',
          group: 'Document Type',
          weight: 13,
        },
        {
          name: 'Housing Authority Eligibility',
          group: 'Document Type',
          weight: 14,
        },
        {
          name: 'Other',
          group: 'Document Type',
          note: 'Please specify contents under note',
          weight: 15,
        },
      ]
    end
  end
end
