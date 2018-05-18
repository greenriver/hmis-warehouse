# module Health
#   class SdhCaseManagementNoteActivity < HealthBase

#     MODE_OF_CONTACT = [
#       'In Person',
#       'Phone call',
#       'Email',
#       'Video call',
#       'Other'
#     ]
#     MODE_OF_CONTACT_OTHER = 'Other'

#     REACHED_CLIENT = [
#       'Yes (face to face, phone call answered, response to email)',
#       'Group session',
#       'Did not reach',
#       'Collateral contact - not with client directly'
#     ]
#     REACHED_CLIENT_OTHER = 'Collateral contact - not with client directly'

#     ACTIVITY = [
#       'Outreach for enrollment',
#       'Care coordination',
#       'Care planning',
#       'Comprehensive Health Assessment',
#       'Follow-up within 3 days of hospital discharge (with client)',
#       'Care transitions (working with care team)',
#       'Health and wellness coaching',
#       'Connection to community and social services',
#       'Social services screening completed',
#       'Referral to ACO for Flexible Services'
#     ]

#     belongs_to :note, class_name: 'Health::SdhCaseManagementNote', foreign_key: 'note_id'

#     validates :mode_of_contact, inclusion: {in: MODE_OF_CONTACT}, allow_nil: true
#     validates :reached_client, inclusion: {in: REACHED_CLIENT}, allow_nil: true
#     validates :activity, inclusion: {in: ACTIVITY}, allow_nil: true 

#     def self.load_string_collection(collection)
#       [['None', '']] + collection.map do |c|
#         [c, c]
#       end
#     end

#     def self.mode_of_contact_collection
#       self.load_string_collection(MODE_OF_CONTACT)
#     end

#     def self.reached_client_collection
#       self.load_string_collection(REACHED_CLIENT)
#     end

#     def self.activity_collection
#       self.load_string_collection(ACTIVITY)
#     end

#     def mode_of_contact_is_other?
#       mode_of_contact == MODE_OF_CONTACT_OTHER
#     end

#     def mode_of_contact_other_value
#       MODE_OF_CONTACT_OTHER
#     end

#     def reached_client_is_collateral_contact?
#       reached_client == REACHED_CLIENT_OTHER
#     end

#     def reached_client_collateral_contact_value
#       REACHED_CLIENT_OTHER
#     end

#     def display_sections(index)
#       {
#         subtitle: "Qualifying Activity ##{index+1}",
#         values: [
#           {key: 'Mode of Contact:', value: mode_of_contact, other: (mode_of_contact_is_other? ? {key: 'Other:', value: mode_of_contact_other} : false)},
#           {key: 'Reached Client:', value: reached_client, other: (reached_client_is_collateral_contact? ? {key: 'Collateral Contact:', value: reached_client_collateral_contact} : false)},
#           {key: 'Which type of activity took place?', value: activity, include_br_before: true}
#         ]
#       }
#     end

#   end
# end