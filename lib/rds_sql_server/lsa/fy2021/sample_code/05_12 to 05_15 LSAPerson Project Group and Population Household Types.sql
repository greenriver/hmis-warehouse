/*
LSA FY2021 Sample Code

Name:  05_12 to 05_15 LSAPerson Project Group and Population Household Types.sql  
Date:  6 OCT 2021

	
	5.12 Set Population Identifiers for Active HouseholdIDs
*/

	update hhid
	set hhid.HHChronic = coalesce((select min(
					case when (lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
							or (lp.CHTime = 400 and lp.CHTimeStatus = 2) then 1
						when lp.CHTime in (365, 400) then 2
						when lp.CHTime = 270 and lp.DisabilityStatus = 1 then 3
					else null end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1 
				and n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHVet = (select max(
					case when lp.VetStatus = 1 
						and n.ActiveAge between 18 and 65 
						and hh.ActiveHHType <> 3 then 1
					else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID)
		, hhid.HHDisability = (select max(
				case when lp.DisabilityStatus = 1 
					and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
				else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID)
		, hhid.HHFleeingDV = (select max(
				case when lp.DVStatus = 1 
					and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
				else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID)
		--Set HHAdultAge for active households based on HH member AgeGroup(s) 
		, hhid.HHAdultAge = (select 
				-- n/a for households with member(s) of unknown age
				case when max(n.ActiveAge) >= 98 then -1
					-- n/a for CO households
					when max(n.ActiveAge) <= 17 then -1
					-- 18-21
					when max(n.ActiveAge) = 21 then 18
					-- 22-24
					when max(n.ActiveAge) = 24 then 24
					-- 55+
					when min(n.ActiveAge) between 64 and 65 then 55
					-- all other combinations
					else 25 end
				from tlsa_Enrollment n 
				where n.HouseholdID = hhid.HouseholdID and n.Active = 1) 
		, hhid.AC3Plus = (select case sum(case when n.ActiveAge <= 17 and hh.ActiveHHType = 2 then 1
								else 0 end) 
							when 0 then 0 
							when 1 then 0 
							when 2 then 0 
							else 1 end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
				where n.Active = 1 and n.HouseholdID = hhid.HouseholdID) 
		, hhid.Step = '5.12.1'
	from tlsa_HHID hhid
	where hhid.Active = 1

	update hhid
	set hhid.HHParent = (select max(
			case when n.RelationshipToHoH = 2 then 1
				else 0 end)
		from tlsa_Enrollment n 
		where n.Active = 1 and n.HouseholdID = hhid.HouseholdID)
		, hhid.Step = '5.12.2'
	from tlsa_HHID hhid
	where hhid.Active = 1


/*
	5.13 Set tlsa_Person Project Group and Population Household Types
*/


	update lp
	set lp.HHTypeEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)) 
		, lp.HoHEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and n.RelationshipToHoH = 1) 
		, lp.AdultEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and n.ActiveAge between 18 and 65) 
		, lp.AHAREST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType in (0,1,2,8)) 
		, lp.AHARHoHEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR= 1 and n.LSAProjectType in (0,1,2,8)
					and n.RelationshipToHoH = 1) 
		, lp.AHARAdultEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType in (0,1,2,8)
					and n.ActiveAge between 18 and 65) 
		, lp.HHChronicEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHChronic = 1)
		, lp.HHVetEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHVet = 1)
		, lp.HHDisabilityEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHDisability = 1)
		, lp.HHFleeingDVEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHFleeingDV = 1)
		, lp.HHParentEST = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.HHParent = 1)
		, lp.AC3PlusEST = (select sum(distinct case when hhid.AC3Plus = 1 then 1 else 0 end)
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8)
					and hhid.AC3Plus = 1)
		, lp.HHTypeRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13) 
		, lp.HoHRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and n.RelationshipToHoH = 1) 
		, lp.AdultRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and n.ActiveAge between 18 and 65) 
		, lp.AHARRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 13) 
		, lp.AHARHoHRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 13
					and n.RelationshipToHoH = 1) 
		, lp.AHARAdultRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 13
					and n.ActiveAge between 18 and 65) 
		, lp.HHChronicRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHChronic = 1)
		, lp.HHVetRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHVet = 1)
		, lp.HHDisabilityRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHDisability = 1)
		, lp.HHFleeingDVRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHFleeingDV = 1)
		, lp.HHParentRRH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.HHParent = 1)
		, lp.AC3PlusRRH = (select sum(distinct case when hhid.AC3Plus = 1 then 1 else 0 end)
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13
					and hhid.AC3Plus = 1)
		, lp.HHTypePSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3) 
		, lp.HoHPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and n.RelationshipToHoH = 1) 
		, lp.AdultPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and n.ActiveAge between 18 and 65) 
		, lp.AHARPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 3) 
		, lp.AHARHoHPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 3
					and n.RelationshipToHoH = 1) 
		, lp.AHARAdultPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.AHAR = 1 and n.LSAProjectType = 3
					and n.ActiveAge between 18 and 65) 
		, lp.HHChronicPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHChronic = 1)
		, lp.HHVetPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHVet = 1)
		, lp.HHDisabilityPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHDisability = 1)
		, lp.HHFleeingDVPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHFleeingDV = 1)
		, lp.HHParentPSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.HHParent = 1)
		, lp.AC3PlusPSH = (select sum(distinct case when hhid.AC3Plus = 1 then 1 else 0 end)
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3
					and hhid.AC3Plus = 1)
		, lp.Step = '5.13'
	from tlsa_Person lp

	update lp set lp.AC3PlusEST = case when lp.AC3PlusEST is NULL then -1 else cast(replace(cast(lp.AC3PlusEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AC3PlusPSH = case when lp.AC3PlusPSH is NULL then -1 else cast(replace(cast(lp.AC3PlusPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AC3PlusRRH = case when lp.AC3PlusRRH is NULL then -1 else cast(replace(cast(lp.AC3PlusRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AdultEST = case when lp.AdultEST is NULL then -1 else cast(replace(cast(lp.AdultEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AdultPSH = case when lp.AdultPSH is NULL then -1 else cast(replace(cast(lp.AdultPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AdultRRH = case when lp.AdultRRH is NULL then -1 else cast(replace(cast(lp.AdultRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARAdultEST = case when lp.AHARAdultEST is NULL then -1 else cast(replace(cast(lp.AHARAdultEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARAdultPSH = case when lp.AHARAdultPSH is NULL then -1 else cast(replace(cast(lp.AHARAdultPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARAdultRRH = case when lp.AHARAdultRRH is NULL then -1 else cast(replace(cast(lp.AHARAdultRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHAREST = case when lp.AHAREST is NULL then -1 else cast(replace(cast(lp.AHAREST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARHoHEST = case when lp.AHARHoHEST is NULL then -1 else cast(replace(cast(lp.AHARHoHEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARHoHPSH = case when lp.AHARHoHPSH is NULL then -1 else cast(replace(cast(lp.AHARHoHPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARHoHRRH = case when lp.AHARHoHRRH is NULL then -1 else cast(replace(cast(lp.AHARHoHRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARPSH = case when lp.AHARPSH is NULL then -1 else cast(replace(cast(lp.AHARPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.AHARRRH = case when lp.AHARRRH is NULL then -1 else cast(replace(cast(lp.AHARRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHChronicEST = case when lp.HHChronicEST is NULL then -1 else cast(replace(cast(lp.HHChronicEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHChronicPSH = case when lp.HHChronicPSH is NULL then -1 else cast(replace(cast(lp.HHChronicPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHChronicRRH = case when lp.HHChronicRRH is NULL then -1 else cast(replace(cast(lp.HHChronicRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHDisabilityEST = case when lp.HHDisabilityEST is NULL then -1 else cast(replace(cast(lp.HHDisabilityEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHDisabilityPSH = case when lp.HHDisabilityPSH is NULL then -1 else cast(replace(cast(lp.HHDisabilityPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHDisabilityRRH = case when lp.HHDisabilityRRH is NULL then -1 else cast(replace(cast(lp.HHDisabilityRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHFleeingDVEST = case when lp.HHFleeingDVEST is NULL then -1 else cast(replace(cast(lp.HHFleeingDVEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHFleeingDVPSH = case when lp.HHFleeingDVPSH is NULL then -1 else cast(replace(cast(lp.HHFleeingDVPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHFleeingDVRRH = case when lp.HHFleeingDVRRH is NULL then -1 else cast(replace(cast(lp.HHFleeingDVRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHParentEST = case when lp.HHParentEST is NULL then -1 else cast(replace(cast(lp.HHParentEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHParentPSH = case when lp.HHParentPSH is NULL then -1 else cast(replace(cast(lp.HHParentPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHParentRRH = case when lp.HHParentRRH is NULL then -1 else cast(replace(cast(lp.HHParentRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHTypeEST = case when lp.HHTypeEST is NULL then -1 else cast(replace(cast(lp.HHTypeEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHTypePSH = case when lp.HHTypePSH is NULL then -1 else cast(replace(cast(lp.HHTypePSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHTypeRRH = case when lp.HHTypeRRH is NULL then -1 else cast(replace(cast(lp.HHTypeRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHVetEST = case when lp.HHVetEST is NULL then -1 else cast(replace(cast(lp.HHVetEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHVetPSH = case when lp.HHVetPSH is NULL then -1 else cast(replace(cast(lp.HHVetPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HHVetRRH = case when lp.HHVetRRH is NULL then -1 else cast(replace(cast(lp.HHVetRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HoHEST = case when lp.HoHEST is NULL then -1 else cast(replace(cast(lp.HoHEST as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HoHPSH = case when lp.HoHPSH is NULL then -1 else cast(replace(cast(lp.HoHPSH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.HoHRRH = case when lp.HoHRRH is NULL then -1 else cast(replace(cast(lp.HoHRRH as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.PSHAgeMax = case when lp.PSHAgeMax is NULL then -1 else cast(replace(cast(lp.PSHAgeMax as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.PSHAgeMin = case when lp.PSHAgeMin is NULL then -1 else cast(replace(cast(lp.PSHAgeMin as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.RRHAgeMax = case when lp.RRHAgeMax is NULL then -1 else cast(replace(cast(lp.RRHAgeMax as varchar), '0', '') as int) end from tlsa_Person lp
	update lp set lp.RRHAgeMin = case when lp.RRHAgeMin is NULL then -1 else cast(replace(cast(lp.RRHAgeMin as varchar), '0', '') as int) end from tlsa_Person lp
	   	  
	/*
		5.14 Adult Age Population Identifiers - LSAPerson
	*/
	update lp
	set lp.HHAdultAgeAOEST = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.LSAProjectType in (0,1,2,8)
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACEST = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.LSAProjectType in (0,1,2,8)
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeAORRH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.LSAProjectType = 13
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACRRH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.LSAProjectType = 13
				where n.PersonalID = lp.PersonalID
					and n.Active = 1), -1)
		, lp.HHAdultAgeAOPSH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 1 
					and hhid.LSAProjectType = 3
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.HHAdultAgeACPSH = coalesce((select case when min(hhid.HHAdultAge) between 18 and 24
					then min(hhid.HHAdultAge) 
				else max(hhid.HHAdultAge) end
				from tlsa_Enrollment n 
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
					and hhid.HHAdultAge between 18 and 55 and hhid.ActiveHHType = 2
					and hhid.LSAProjectType = 3
				where n.PersonalID = lp.PersonalID and n.Active = 1), -1)
		, lp.Step = '5.14'
	from tlsa_Person lp

/*
	5.15 Select Data for Export to LSAPerson
*/
	-- LSAPerson
	delete from lsa_Person
	insert into lsa_Person (RowTotal
		, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, ReportID 
		)
	select count(distinct PersonalID)
		, Gender, Race, Ethnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, ReportID 
	from tlsa_Person
	group by 
		Gender, Race, Ethnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, ReportID 
	
/*
	End LSAPerson
*/
