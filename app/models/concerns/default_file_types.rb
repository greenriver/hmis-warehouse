module DefaultFileTypes
  extend ActiveSupport::Concern
  class_methods do
    def default_document_types
      [
        {
          name: 'Birth Certificate',
          group: 'Birth Certificate',
          included_info: 'DoB, citizenship',
        },
        {
          name: 'State ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
        },
        {
          name: 'Passport',
          group: 'Photo ID',
          included_info: 'Photo ID',
        },
        {
          name: 'Federal Government ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
        },
        {
          name: 'Shelter ID',
          group: 'Photo ID',
          included_info: 'Photo ID',
        },
        {
          name: 'HAN Release',
          group: 'HAN Release',
          included_info: 'Network Data Sharing Release',
        },
        {
          name: 'DD 214',
          group: 'Verification of Veteran Status',
          included_info: 'Vets Status, DoB, SSN',
        },
        {
          name: 'Letter of Service',
          group: 'Verification of Veteran Status',
          included_info: 'Vets Status, DoB, SSN',
        },
        {
          name: 'Verification of Disability',
          group: 'Verification of Disability',
          included_info: 'Verification of Disability',
          note: 'This verification form certifies ONLY that you have the appropriate medical document and certifications on file at your agency for this Client.  This verification should not include any reference whatsoever regarding the actual disability type or reason for disability for a client. '
        },
        {
          name: 'Homeless Verification',
          group: 'Homeless Verification',
          included_info: 'Non-HMIS Verification for Boston',
        },
        {
          name: 'Limited CAS Release',
          group: 'Limited CAS Release',
          included_info: 'Verification of interest in housing',
        },
        {
          name: 'Pay Stubs',
          group: 'Verification of Income',
          included_info: 'Verification of Income',
        },
        {
          name: 'SSDI Printout',
          group: 'Verification of Income',
          included_info: 'Verification of Income, Verification of Disability',
        },
        {
          name: 'SSI Printout',
          group: 'Verification of Income',
          included_info: 'Verification of Income',
        },
        {
          name: 'SSDI Check',
          group: 'Verification of Income',
          included_info: 'Verification of Income, Verification of Disability',
        },
        {
          name: 'SSI Check',
          group: 'Verification of Income',
          included_info: 'Verification of Income',
        },
        {
          name: 'VA Benefit Letter',
          group: 'Verification of Income',
          included_info: 'Verification of Income, Verification of Disability',
        },
        {
          name: 'VA Benefit Check',
          group: 'Verification of Income',
          included_info: 'Verification of Income, Verification of Disability',
        },
        {
          name: 'EAEDC Printout',
          group: 'Verification of Income',
          included_info: 'Verification of Income',
        },
        {
          name: 'SSP Printout',
          group: 'Verification of Income',
          included_info: 'Verification of Income',
        },
        {
          name: 'Social Security Card',
          group: 'Social Security Card',
          included_info: 'SSN',
        },
        {
          name: 'CoC CORI Release',
          group: 'CoC CORI Release',
          included_info: 'CoC CORI Release',
        },
        {
          name: 'Green Card',
          group: 'Verification of Citizenship',
          included_info: 'SSN',
        },
        {
          name: 'BHA CAS Referral',
          group: 'BHA CAS Referral',
          included_info: 'BHA CAS Referral',
        },
        {
          name: 'Verification of Program Enrollment for CAS',
          group: 'Verification of Program Enrollment for CAS',
          included_info: 'Verification of Program Enrollment for CAS',
        },
        {
          name: 'BHA CORI Request',
          group: 'BHA CORI Request',
          included_info: 'BHA CORI Request',
        },
        {
          name: 'BHA Application',
          group: 'BHA Application',
          included_info: 'BHA Application',
        },
        {
          name: 'Other',
          group: 'Other',
          note: 'Please specify contents under note',
        },
      ]
    end
  end
end