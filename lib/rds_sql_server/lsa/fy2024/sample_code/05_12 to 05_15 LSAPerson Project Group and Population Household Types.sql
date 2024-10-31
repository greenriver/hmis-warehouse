/*
LSA FY2024 Sample Code
Name:  05_12 to 05_15 LSAPerson Project Group and Population Household Types.sql  

FY2024 Changes

		None

		(Detailed revision history maintained at https://github.com/HMIS/LSASampleCode
	
	5.12 Set Population Identifiers for Active HouseholdIDs
*/

	update hhid
	set hhid.HHChronic = coalesce((select min(
			case when ((lp.CHTime = 365 and lp.CHTimeStatus in (1,2))
					or (lp.CHTime = 400 and lp.CHTimeStatus = 2))
					and lp.DisabilityStatus = 1 then 1
				when lp.CHTime in (365, 400) and lp.DisabilityStatus = 1 then 2
				when lp.CHTime in (365, 400) and lp.DisabilityStatus = 99 then 3
				when lp.CHTime in (365, 400) and lp.DisabilityStatus = 0 then 4
				when lp.CHTime = 270 and lp.DisabilityStatus = 1 and lp.CHTimeStatus = 99 then 5
				when lp.CHTime = 270 and lp.DisabilityStatus = 1 and lp.CHTimeStatus <> 99 then 6
				when lp.CHTimeStatus = 99 and lp.DisabilityStatus <> 0 then 9
				else null end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1 
				and (n.RelationshipToHoH = 1 or n.ActiveAge between 18 and 65)
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHVet = coalesce((select max(
					case when lp.VetStatus = 1 
						and n.ActiveAge between 18 and 65 
						and hh.ActiveHHType <> 3 then 1
					else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			inner join tlsa_HHID hh on hh.HouseholdID = n.HouseholdID
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHDisability = coalesce((select max(
				case when lp.DisabilityStatus = 1 
					and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
				else 0 end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID), 0)
		, hhid.HHFleeingDV = coalesce((select min(
				case when lp.DVStatus = 1 
						and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 1
					when lp.DVStatus in (2,3) 
						and (n.ActiveAge between 18 and 65 or n.RelationshipToHoH = 1) then 2
				else null end)
			from tlsa_Person lp
			inner join tlsa_Enrollment n on n.PersonalID = lp.PersonalID and n.Active = 1
			where n.HouseholdID = hhid.HouseholdID), 0)
		--Set HHAdultAge for active households based on HH member AgeGroup(s) 
		, hhid.HHAdultAge = (select 
				-- n/a except for AO and AC households 
				case when hhid.ActiveHHType not in (1,2) then -1
					-- n/a for AC households with members of unknown age
					when max(n.ActiveAge) >= 98 then -1
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
	set hhid.HHParent = coalesce((select max(
			case when n.RelationshipToHoH = 2 then 1
				else 0 end)
		from tlsa_Enrollment n 
		where n.Active = 1 and n.HouseholdID = hhid.HouseholdID), 0)
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
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1,2,8))
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
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 13)
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
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 3)
		, lp.HHTypeRRHSONoMI = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.MoveInDate is null and n.LSAProjectType = 15) 
		, lp.HHTypeRRHSOMI = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.MoveInDate is not null and n.LSAProjectType = 15) 
		, lp.HHTypeES = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType in (0,1)) 
		, lp.HHTypeSH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 8) 
		, lp.HHTypeTH = (select sum(distinct case hhid.ActiveHHType 
					when 1 then 1000
					when 2 then 200
					when 3 then 30
					else 9 end) 
				from tlsa_Enrollment n
				inner join tlsa_HHID hhid on hhid.HouseholdID = n.HouseholdID
				where n.PersonalID = lp.PersonalID and n.Active = 1 and n.LSAProjectType = 2) 
		, lp.Step = '5.13.1'
	from tlsa_Person lp

	update lp 
	set lp.AC3PlusEST = case when lp.AC3PlusEST is NULL then -1 else cast(replace(cast(lp.AC3PlusEST as varchar), '0', '') as int) end 
	, lp.AC3PlusPSH = case when lp.AC3PlusPSH is NULL then -1 else cast(replace(cast(lp.AC3PlusPSH as varchar), '0', '') as int) end  
	, lp.AC3PlusRRH = case when lp.AC3PlusRRH is NULL then -1 else cast(replace(cast(lp.AC3PlusRRH as varchar), '0', '') as int) end  
	, lp.AdultEST = case when lp.AdultEST is NULL then -1 else cast(replace(cast(lp.AdultEST as varchar), '0', '') as int) end   
	, lp.AdultPSH = case when lp.AdultPSH is NULL then -1 else cast(replace(cast(lp.AdultPSH as varchar), '0', '') as int) end   
	, lp.AdultRRH = case when lp.AdultRRH is NULL then -1 else cast(replace(cast(lp.AdultRRH as varchar), '0', '') as int) end   
	, lp.AHARAdultEST = case when lp.AHARAdultEST is NULL then -1 else cast(replace(cast(lp.AHARAdultEST as varchar), '0', '') as int) end   
	, lp.AHARAdultPSH = case when lp.AHARAdultPSH is NULL then -1 else cast(replace(cast(lp.AHARAdultPSH as varchar), '0', '') as int) end 
	, lp.AHARAdultRRH = case when lp.AHARAdultRRH is NULL then -1 else cast(replace(cast(lp.AHARAdultRRH as varchar), '0', '') as int) end 
	, lp.AHAREST = case when lp.AHAREST is NULL then -1 else cast(replace(cast(lp.AHAREST as varchar), '0', '') as int) end 
	, lp.AHARHoHEST = case when lp.AHARHoHEST is NULL then -1 else cast(replace(cast(lp.AHARHoHEST as varchar), '0', '') as int) end 
	, lp.AHARHoHPSH = case when lp.AHARHoHPSH is NULL then -1 else cast(replace(cast(lp.AHARHoHPSH as varchar), '0', '') as int) end 
	, lp.AHARHoHRRH = case when lp.AHARHoHRRH is NULL then -1 else cast(replace(cast(lp.AHARHoHRRH as varchar), '0', '') as int) end 
	, lp.AHARPSH = case when lp.AHARPSH is NULL then -1 else cast(replace(cast(lp.AHARPSH as varchar), '0', '') as int) end 
	, lp.AHARRRH = case when lp.AHARRRH is NULL then -1 else cast(replace(cast(lp.AHARRRH as varchar), '0', '') as int) end 
	, lp.HHChronicEST = case when lp.HHChronicEST is NULL then -1 else cast(replace(cast(lp.HHChronicEST as varchar), '0', '') as int) end 
	, lp.HHChronicPSH = case when lp.HHChronicPSH is NULL then -1 else cast(replace(cast(lp.HHChronicPSH as varchar), '0', '') as int) end 
	, lp.HHChronicRRH = case when lp.HHChronicRRH is NULL then -1 else cast(replace(cast(lp.HHChronicRRH as varchar), '0', '') as int) end 
	, lp.HHDisabilityEST = case when lp.HHDisabilityEST is NULL then -1 else cast(replace(cast(lp.HHDisabilityEST as varchar), '0', '') as int) end 
	, lp.HHDisabilityPSH = case when lp.HHDisabilityPSH is NULL then -1 else cast(replace(cast(lp.HHDisabilityPSH as varchar), '0', '') as int) end 
	, lp.HHDisabilityRRH = case when lp.HHDisabilityRRH is NULL then -1 else cast(replace(cast(lp.HHDisabilityRRH as varchar), '0', '') as int) end 
	, lp.HHFleeingDVEST = case when lp.HHFleeingDVEST is NULL then -1 else cast(replace(cast(lp.HHFleeingDVEST as varchar), '0', '') as int) end 
	, lp.HHFleeingDVPSH = case when lp.HHFleeingDVPSH is NULL then -1 else cast(replace(cast(lp.HHFleeingDVPSH as varchar), '0', '') as int) end 
	, lp.HHFleeingDVRRH = case when lp.HHFleeingDVRRH is NULL then -1 else cast(replace(cast(lp.HHFleeingDVRRH as varchar), '0', '') as int) end 
	, lp.HHParentEST = case when lp.HHParentEST is NULL then -1 else cast(replace(cast(lp.HHParentEST as varchar), '0', '') as int) end 
	, lp.HHParentPSH = case when lp.HHParentPSH is NULL then -1 else cast(replace(cast(lp.HHParentPSH as varchar), '0', '') as int) end 
	, lp.HHParentRRH = case when lp.HHParentRRH is NULL then -1 else cast(replace(cast(lp.HHParentRRH as varchar), '0', '') as int) end 
	, lp.HHTypeEST = case when lp.HHTypeEST is NULL then -1 else cast(replace(cast(lp.HHTypeEST as varchar), '0', '') as int) end 
	, lp.HHTypePSH = case when lp.HHTypePSH is NULL then -1 else cast(replace(cast(lp.HHTypePSH as varchar), '0', '') as int) end 
	, lp.HHTypeRRH = case when lp.HHTypeRRH is NULL then -1 else cast(replace(cast(lp.HHTypeRRH as varchar), '0', '') as int) end 
	, lp.HHVetEST = case when lp.HHVetEST is NULL then -1 else cast(replace(cast(lp.HHVetEST as varchar), '0', '') as int) end 
	, lp.HHVetPSH = case when lp.HHVetPSH is NULL then -1 else cast(replace(cast(lp.HHVetPSH as varchar), '0', '') as int) end 
	, lp.HHVetRRH = case when lp.HHVetRRH is NULL then -1 else cast(replace(cast(lp.HHVetRRH as varchar), '0', '') as int) end 
	, lp.HoHEST = case when lp.HoHEST is NULL then -1 else cast(replace(cast(lp.HoHEST as varchar), '0', '') as int) end 
	, lp.HoHPSH = case when lp.HoHPSH is NULL then -1 else cast(replace(cast(lp.HoHPSH as varchar), '0', '') as int) end 
	, lp.HoHRRH = case when lp.HoHRRH is NULL then -1 else cast(replace(cast(lp.HoHRRH as varchar), '0', '') as int) end 
	, lp.HHTypeES = case when lp.HHTypeES is NULL then -1 else cast(replace(cast(lp.HHTypeES as varchar), '0', '') as int) end 
	, lp.HHTypeSH = case when lp.HHTypeSH is NULL then -1 else cast(replace(cast(lp.HHTypeSH as varchar), '0', '') as int) end 
	, lp.HHTypeTH = case when lp.HHTypeTH is NULL then -1 else cast(replace(cast(lp.HHTypeTH as varchar), '0', '') as int) end 
	, lp.PSHAgeMax = case when lp.PSHAgeMax is NULL then -1 else lp.PSHAgeMax end 
	, lp.PSHAgeMin = case when lp.PSHAgeMin is NULL then -1 else lp.PSHAgeMin end 
	, lp.RRHAgeMax = case when lp.RRHAgeMax is NULL then -1 else lp.RRHAgeMax end 
	, lp.RRHAgeMin = case when lp.RRHAgeMin is NULL then -1 else lp.RRHAgeMin end 
	, lp.ESTAgeMax = case when lp.ESTAgeMax is NULL then -1 else lp.ESTAgeMax end 
	, lp.ESTAgeMin = case when lp.ESTAgeMin is NULL then -1 else lp.ESTAgeMin end 
	, lp.RRHSOAgeMin = case when lp.RRHSOAgeMin is NULL then -1 else lp.RRHSOAgeMin end    
	, lp.RRHSOAgeMax = case when lp.RRHSOAgeMax is NULL then -1 else lp.RRHSOAgeMax end    
	, lp.HHTypeRRHSONoMI = case when lp.HHTypeRRHSONoMI is NULL then -1 else cast(replace(cast(lp.HHTypeRRHSONoMI as varchar), '0', '') as int) end 
	, lp.HHTypeRRHSOMI = case when lp.HHTypeRRHSOMI is NULL then -1 else cast(replace(cast(lp.HHTypeRRHSOMI as varchar), '0', '') as int) end 
	, Step = '5.13.2'
	from tlsa_Person lp
	
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
		, Gender, RaceEthnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, RRHSOAgeMin, RRHSOAgeMax, HHTypeRRHSONoMI, HHTypeRRHSOMI
		, HHTypeES, HHTypeSH, HHTypeTH, HIV, SMI, SUD
		, ReportID 
		)
	select count(distinct PersonalID)
		, Gender, RaceEthnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, RRHSOAgeMin, RRHSOAgeMax, HHTypeRRHSONoMI, HHTypeRRHSOMI
		, HHTypeES, HHTypeSH, HHTypeTH, HIV, SMI, SUD
		, ReportID 
	from tlsa_Person
	group by 
		Gender, RaceEthnicity, VetStatus, DisabilityStatus
		, CHTime, CHTimeStatus, DVStatus
		, ESTAgeMin, ESTAgeMax, HHTypeEST, HoHEST, AdultEST, AHARAdultEST, HHChronicEST, HHVetEST, HHDisabilityEST
		, HHFleeingDVEST, HHAdultAgeAOEST, HHAdultAgeACEST, HHParentEST, AC3PlusEST, AHAREST, AHARHoHEST
		, RRHAgeMin, RRHAgeMax, HHTypeRRH, HoHRRH, AdultRRH, AHARAdultRRH, HHChronicRRH, HHVetRRH, HHDisabilityRRH
		, HHFleeingDVRRH, HHAdultAgeAORRH, HHAdultAgeACRRH, HHParentRRH, AC3PlusRRH, AHARRRH, AHARHoHRRH
		, PSHAgeMin, PSHAgeMax, HHTypePSH, HoHPSH, AdultPSH, AHARAdultPSH, HHChronicPSH, HHVetPSH, HHDisabilityPSH
		, HHFleeingDVPSH, HHAdultAgeAOPSH, HHAdultAgeACPSH, HHParentPSH, AC3PlusPSH, AHARPSH, AHARHoHPSH
		, RRHSOAgeMin, RRHSOAgeMax, HHTypeRRHSONoMI, HHTypeRRHSOMI
		, HHTypeES, HHTypeSH, HHTypeTH, HIV, SMI, SUD
		, ReportID 
	
/*
	End LSAPerson
*/
