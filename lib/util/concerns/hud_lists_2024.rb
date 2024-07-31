###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY
module Concerns::HudLists2024
  extend ActiveSupport::Concern
  class_methods do
    # 1.1
    def period_types
      {
        1 => 'Updated',
        3 => 'Reporting period',
        4 => 'Other',
      }.freeze
    end

    def export_period_type(id, reverse = false, raise_on_missing: false)
      _translate(period_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.10
    def no_yes_options
      {
        0 => 'No',
        1 => 'Yes',
      }.freeze
    end

    def no_yes(id, reverse = false, raise_on_missing: false)
      _translate(no_yes_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.2
    def export_directives
      {
        1 => 'Delta refresh',
        2 => 'Full refresh',
        3 => 'Other',
      }.freeze
    end

    def export_directive(id, reverse = false, raise_on_missing: false)
      _translate(export_directives, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.3
    def disability_types
      {
        5 => 'Physical disability',
        6 => 'Developmental disability',
        7 => 'Chronic health condition',
        8 => 'HIV/AIDS',
        9 => 'Mental health disorder',
        10 => 'Substance use disorder',
      }.freeze
    end

    def disability_type(id, reverse = false, raise_on_missing: false)
      _translate(disability_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.4
    def record_types
      {
        141 => 'PATH Service',
        142 => 'RHY Service Connections',
        143 => 'HOPWA Service',
        144 => 'SSVF Service',
        151 => 'HOPWA Financial Assistance',
        152 => 'SSVF Financial Assistance',
        161 => 'PATH Referral',
        200 => 'Bed Night',
        210 => 'HUD-VASH OTH Voucher Tracking',
        300 => 'Moving On Assistance',
      }.freeze
    end

    def record_type(id, reverse = false, raise_on_missing: false)
      _translate(record_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.5
    def hash_statuses
      {
        1 => 'Unhashed',
        2 => 'SHA-1 RHY',
        3 => 'Hashed - other',
        4 => 'SHA-256 (RHY)',
      }.freeze
    end

    def hash_status(id, reverse = false, raise_on_missing: false)
      _translate(hash_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.6
    def race_nones
      {
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def race_none(id, reverse = false, raise_on_missing: false)
      _translate(race_nones, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.7
    def yes_no_missing_options
      {
        0 => 'No',
        1 => 'Yes',
        99 => 'Data not collected',
      }.freeze
    end

    def no_yes_missing(id, reverse = false, raise_on_missing: false)
      _translate(yes_no_missing_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.8
    def no_yes_reasons_for_missing_data_options
      {
        0 => 'No',
        1 => 'Yes',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def no_yes_reasons_for_missing_data(id, reverse = false, raise_on_missing: false)
      _translate(no_yes_reasons_for_missing_data_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 1.9
    def source_types
      {
        1 => 'CoC HMIS',
        2 => 'Standalone/agency-specific application',
        3 => 'Data warehouse',
        4 => 'Other',
      }.freeze
    end

    def source_type(id, reverse = false, raise_on_missing: false)
      _translate(source_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.02.6
    def project_types
      {
        0 => 'Emergency Shelter - Entry Exit',
        1 => 'Emergency Shelter - Night-by-Night',
        2 => 'Transitional Housing',
        3 => 'PH - Permanent Supportive Housing',
        4 => 'Street Outreach',
        6 => 'Services Only',
        8 => 'Safe Haven',
        9 => 'PH - Housing Only',
        7 => 'Other',
        10 => 'PH - Housing with Services (no disability required for entry)',
        11 => 'Day Shelter',
        12 => 'Homelessness Prevention',
        13 => 'PH - Rapid Re-Housing',
        14 => 'Coordinated Entry',
      }.freeze
    end

    def project_type(id, reverse = false, raise_on_missing: false)
      _translate(project_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.02.6.brief
    def project_type_briefs
      {
        0 => 'ES - Entry/Exit',
        1 => 'ES - NBN',
        2 => 'TH',
        3 => 'PH - PSH',
        4 => 'SO',
        6 => 'SSO',
        8 => 'SH',
        9 => 'PH - PH',
        7 => 'Other',
        10 => 'PH - OPH',
        11 => 'Day Shelter',
        12 => 'HP',
        13 => 'PH - RRH',
        14 => 'CE',
      }.freeze
    end

    def project_type_brief(id, reverse = false, raise_on_missing: false)
      _translate(project_type_briefs, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.02.7
    def target_populations
      {
        1 => 'DV: Survivor of Domestic Violence',
        3 => 'HIV: Persons with HIV/AIDS',
        4 => 'NA: Not applicable',
      }.freeze
    end

    def target_population(id, reverse = false, raise_on_missing: false)
      _translate(target_populations, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.02.8
    def hopwa_med_assisted_living_facs
      {
        0 => 'No',
        1 => 'Yes',
        2 => 'Non-HOPWA Funded Project',
      }.freeze
    end

    def hopwa_med_assisted_living_fac(id, reverse = false, raise_on_missing: false)
      _translate(hopwa_med_assisted_living_facs, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.02.A
    def rrh_sub_types
      {
        1 => 'RRH: Services Only',
        2 => 'RRH: Housing with or without services',
      }.freeze
    end

    def rrh_sub_type(id, reverse = false, raise_on_missing: false)
      _translate(rrh_sub_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.02.D
    def housing_types
      {
        1 => 'Site-based - single site',
        2 => 'Site-based - clustered / multiple sites',
        3 => 'Tenant-based - scattered site',
      }.freeze
    end

    def housing_type(id, reverse = false, raise_on_missing: false)
      _translate(housing_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.03.1
    def coc_codes_options
      {
        'AK-500' => 'Anchorage CoC',
        'AK-501' => 'Alaska Balance of State CoC',
        'AL-500' => 'Birmingham/Jefferson, St. Clair, Shelby Counties CoC',
        'AL-501' => 'Mobile City & County/Baldwin County CoC',
        'AL-502' => 'Florence/Northwest Alabama CoC',
        'AL-503' => 'Huntsville/North Alabama CoC',
        'AL-504' => 'Montgomery City & County CoC',
        'AL-505' => 'Gadsden/Northeast Alabama CoC',
        'AL-506' => 'Tuscaloosa City & County CoC',
        'AL-507' => 'Alabama Balance of State CoC',
        'AR-500' => 'Little Rock/Central Arkansas CoC',
        'AR-501' => 'Fayetteville/Northwest Arkansas CoC',
        'AR-503' => 'Arkansas Balance of State CoC',
        'AR-505' => 'Southeast Arkansas CoC',
        'AR-508' => 'Fort Smith CoC',
        'AS-500' => 'American Samoa CoC',
        'AZ-500' => 'Arizona Balance of State CoC',
        'AZ-501' => 'Tucson/Pima County CoC',
        'AZ-502' => 'Phoenix, Mesa/Maricopa County CoC',
        'CA-500' => 'San Jose/Santa Clara City & County CoC',
        'CA-501' => 'San Francisco CoC',
        'CA-502' => 'Oakland, Berkeley/Alameda County CoC',
        'CA-503' => 'Sacramento City & County CoC',
        'CA-504' => 'Santa Rosa, Petaluma/Sonoma County CoC',
        'CA-505' => 'Contra Costa County CoC',
        'CA-506' => 'Salinas/Monterey, San Benito Counties CoC',
        'CA-507' => 'Marin County CoC',
        'CA-508' => 'Watsonville/Santa Cruz City & County CoC',
        'CA-509' => 'Mendocino County CoC',
        'CA-510' => 'Turlock, Modesto/Stanislaus County CoC',
        'CA-511' => 'Stockton/San Joaquin County CoC',
        'CA-512' => 'Daly City/San Mateo County CoC',
        'CA-513' => 'Visalia/Kings, Tulare Counties CoC',
        'CA-514' => 'Fresno City & County/Madera County CoC',
        'CA-515' => 'Roseville, Rocklin/Placer County',
        'CA-516' => 'Redding/Shasta Siskiyou, Lassen, Plumas, Del Norte, Modoc, Sierra Counties CoC',
        'CA-517' => 'Napa City & County CoC',
        'CA-518' => 'Vallejo/Solano County CoC',
        'CA-519' => 'Chico, Paradise/Butte County CoC',
        'CA-520' => 'Merced City & County CoC',
        'CA-521' => 'Davis, Woodland/Yolo County CoC',
        'CA-522' => 'Humboldt County CoC',
        'CA-523' => 'Colusa, Glen, Trinity Counties CoC',
        'CA-524' => 'Yuba City & County/Sutter County CoC',
        'CA-525' => 'El Dorado County CoC',
        'CA-526' => 'Amador, Calaveras, Mariposa, Tuolumne Counties CoC',
        'CA-527' => 'Tehama County CoC',
        'CA-529' => 'Lake County CoC',
        'CA-530' => 'Alpine, Inyo, Mono Counties CoC',
        'CA-531' => 'Nevada County CoC',
        'CA-600' => 'Los Angeles City & County CoC',
        'CA-601' => 'San Diego City and County CoC',
        'CA-602' => 'Santa Ana, Anaheim/Orange County CoC',
        'CA-603' => 'Santa Maria/Santa Barbara County CoC',
        'CA-604' => 'Bakersfield/Kern County CoC',
        'CA-606' => 'Long Beach CoC',
        'CA-607' => 'Pasadena CoC',
        'CA-608' => 'Riverside City & County CoC',
        'CA-609' => 'San Bernardino City & County CoC',
        'CA-611' => 'Oxnard, San Buenaventura/Ventura County CoC',
        'CA-612' => 'Glendale CoC',
        'CA-613' => 'Imperial County CoC',
        'CA-614' => 'San Luis Obispo County CoC',
        'CO-500' => 'Colorado Balance of State CoC',
        'CO-503' => 'Metropolitan Denver CoC',
        'CO-504' => 'Colorado Springs/El Paso County CoC',
        'CO-505' => 'Fort Collins, Greeley, Loveland/Larimer, Weld Counties CoC',
        'CT-503' => 'Bridgeport, Stamford, Norwalk, Danbury/Fairfield County CoC',
        'CT-505' => 'Connecticut Balance of State CoC',
        'DC-500' => 'District of Columbia CoC',
        'DE-500' => 'Delaware Statewide CoC',
        'FL-500' => 'Sarasota, Bradenton/Manatee, Sarasota Counties CoC',
        'FL-501' => 'Tampa/Hillsborough County CoC',
        'FL-502' => 'St. Petersburg, Clearwater, Largo/Pinellas County CoC',
        'FL-503' => 'Lakeland/Polk County CoC',
        'FL-504' => 'Deltona, Daytona Beach/Volusia, Flagler Counties CoC',
        'FL-505' => 'Fort Walton Beach/Okaloosa, Walton Counties CoC',
        'FL-506' => 'Tallahassee/Leon County CoC',
        'FL-507' => 'Orlando/Orange, Osceola, Seminole Counties CoC',
        'FL-508' => 'Gainesville/Alachua, Putnam Counties CoC',
        'FL-509' => 'Fort Pierce/St. Lucie, Indian River, Martin Counties CoC',
        'FL-510' => 'Jacksonville-Duval, Clay Counties CoC',
        'FL-511' => 'Pensacola/Escambia, Santa Rosa Counties CoC',
        'FL-512' => 'St. Johns County CoC',
        'FL-513' => 'Palm Bay, Melbourne/Brevard County CoC',
        'FL-514' => 'Ocala/Marion County CoC',
        'FL-515' => 'Panama City/Bay, Jackson Counties CoC',
        'FL-517' => 'Hendry, Hardee, Highlands Counties CoC',
        'FL-518' => 'Columbia, Hamilton, Lafayette, Suwannee Counties CoC',
        'FL-519' => 'Pasco County CoC',
        'FL-520' => 'Citrus, Hernando, Lake, Sumter Counties CoC',
        'FL-600' => 'Miami-Dade County CoC',
        'FL-601' => 'Ft Lauderdale/Broward County CoC',
        'FL-602' => 'Charlotte County CoC',
        'FL-603' => 'Ft Myers, Cape Coral/Lee County CoC',
        'FL-604' => 'Monroe County CoC',
        'FL-605' => 'West Palm Beach/Palm Beach County CoC',
        'FL-606' => 'Naples/Collier County CoC',
        'GA-500' => 'Atlanta CoC',
        'GA-501' => 'Georgia Balance of State CoC',
        'GA-502' => 'Fulton County CoC',
        'GA-503' => 'Athens-Clarke County CoC',
        'GA-504' => 'Augusta-Richmond County CoC',
        'GA-505' => 'Columbus-Muscogee/Russell County CoC',
        'GA-506' => 'Marietta/Cobb County CoC',
        'GA-507' => 'Savannah/Chatham County CoC',
        'GA-508' => 'DeKalb County CoC',
        'GU-500' => 'Guam CoC',
        'HI-500' => 'Hawaii Balance of State CoC',
        'HI-501' => 'Honolulu City and County CoC',
        'IA-500' => 'Sioux City/Dakota, Woodbury Counties CoC',
        'IA-501' => 'Iowa Balance of State CoC',
        'IA-502' => 'Des Moines/Polk County CoC',
        'ID-500' => 'Boise/Ada County CoC',
        'ID-501' => 'Idaho Balance of State CoC',
        'IL-500' => 'McHenry County CoC',
        'IL-501' => 'Rockford/DeKalb, Winnebago, Boone Counties CoC',
        'IL-502' => 'Waukegan, North Chicago/Lake County CoC',
        'IL-503' => 'Champaign, Urbana, Rantoul/Champaign County CoC',
        'IL-504' => 'Madison County CoC',
        'IL-506' => 'Joliet, Bolingbrook/Will County CoC',
        'IL-507' => 'Peoria, Pekin/Fulton, Tazewell, Peoria, Woodford Counties CoC',
        'IL-508' => 'East St. Louis, Belleville/St. Clair County CoC',
        'IL-510' => 'Chicago CoC',
        'IL-511' => 'Cook County CoC',
        'IL-512' => 'Bloomington/Central Illinois CoC',
        'IL-513' => 'Springfield/Sangamon County CoC',
        'IL-514' => 'DuPage County CoC',
        'IL-515' => 'South Central Illinois CoC',
        'IL-516' => 'Decatur/Macon County CoC',
        'IL-517' => 'Aurora, Elgin/Kane County CoC',
        'IL-518' => 'Rock Island, Moline/Northwestern Illinois CoC',
        'IL-519' => 'West Central Illinois CoC',
        'IL-520' => 'Southern Illinois CoC',
        'IN-502' => 'Indiana Balance of State CoC',
        'IN-503' => 'Indianapolis CoC',
        'KS-502' => 'Wichita/Sedgwick County CoC',
        'KS-503' => 'Topeka/Shawnee County CoC',
        'KS-505' => 'Overland Park, Shawnee/Johnson County CoC',
        'KS-507' => 'Kansas Balance of State CoC',
        'KY-500' => 'Kentucky Balance of State CoC',
        'KY-501' => 'Louisville-Jefferson County CoC',
        'KY-502' => 'Lexington-Fayette County CoC',
        'LA-500' => 'Lafayette/Acadiana Regional CoC',
        'LA-502' => 'Shreveport, Bossier/Northwest Louisiana CoC',
        'LA-503' => 'New Orleans/Jefferson Parish CoC',
        'LA-505' => 'Monroe/Northeast Louisiana CoC',
        'LA-506' => 'Slidell/Southeast Louisiana CoC',
        'LA-507' => 'Alexandria/Central Louisiana CoC',
        'LA-509' => 'Louisiana Balance of State CoC',
        'MA-500' => 'Boston CoC',
        'MA-502' => 'Lynn CoC',
        'MA-503' => 'Cape Cod Islands CoC',
        'MA-504' => 'Springfield/Hampden County CoC',
        'MA-505' => 'New Bedford CoC',
        'MA-506' => 'Worcester City & County CoC',
        'MA-507' => 'Pittsfield/Berkshire, Franklin, Hampshire Counties CoC',
        'MA-509' => 'Cambridge CoC',
        'MA-511' => 'Quincy, Brockton, Weymouth, Plymouth City and County CoC',
        'MA-515' => 'Fall River CoC',
        'MA-516' => 'Massachusetts Balance of State CoC',
        'MA-519' => 'Attleboro, Taunton/Bristol County CoC',
        'MD-501' => 'Baltimore CoC',
        'MD-503' => 'Annapolis/Anne Arundel County CoC',
        'MD-504' => 'Howard County CoC',
        'MD-505' => 'Baltimore County CoC',
        'MD-506' => 'Carroll County CoC',
        'MD-509' => 'Frederick City & County CoC',
        'MD-511' => 'Mid-Shore Regional CoC',
        'MD-513' => 'Wicomico, Somerset, Worcester Counties CoC',
        'MD-514' => 'Maryland Balance of Sate',
        'MD-600' => "Prince George's County CoC",
        'MD-601' => 'Montgomery County CoC',
        'ME-500' => 'Maine Statewide CoC',
        'MI-500' => 'Michigan Balance of State CoC',
        'MI-501' => 'Detroit CoC',
        'MI-502' => 'Dearborn, Dearborn Heights, Westland/Wayne County CoC',
        'MI-503' => 'St. Clair Shores, Warren/Macomb County CoC',
        'MI-504' => 'Pontiac, Royal Oak/Oakland County CoC',
        'MI-505' => 'Flint/Genesee County CoC',
        'MI-506' => 'Grand Rapids, Wyoming/Kent County CoC',
        'MI-507' => 'Portage, Kalamazoo City & County CoC',
        'MI-508' => 'Lansing, East Lansing/Ingham County CoC',
        'MI-509' => 'Washtenaw County CoC',
        'MI-510' => 'Saginaw City & County CoC',
        'MI-511' => 'Lenawee County CoC',
        'MI-512' => 'Grand Traverse, Antrim, Leelanau Counties CoC',
        'MI-514' => 'Battle Creek/Calhoun County CoC',
        'MI-515' => 'Monroe City & County CoC',
        'MI-516' => 'Norton Shores, Muskegon City & County CoC',
        'MI-517' => 'Jackson City & County CoC',
        'MI-518' => 'Livingston County CoC',
        'MI-519' => 'Holland/Ottawa County CoC',
        'MI-523' => 'Eaton County CoC',
        'MN-500' => 'Minneapolis/Hennepin County CoC',
        'MN-501' => 'St. Paul/Ramsey County CoC',
        'MN-502' => 'Rochester/Southeast Minnesota CoC',
        'MN-503' => 'Dakota, Anoka, Washington, Scott, Carver Counties CoC',
        'MN-504' => 'Northeast Minnesota CoC',
        'MN-505' => 'St. Cloud/Central Minnesota CoC',
        'MN-506' => 'Northwest Minnesota CoC',
        'MN-508' => 'Moorhead/West Central Minnesota CoC',
        'MN-509' => 'Duluth/St. Louis County CoC',
        'MN-511' => 'Southwest Minnesota CoC',
        'MO-500' => 'St. Louis County CoC',
        'MO-501' => 'St. Louis CoC',
        'MO-503' => 'St. Charles, Lincoln, Warren Counties CoC',
        'MO-600' => 'Springfield/Greene, Christian, Webster Counties CoC',
        'MO-602' => 'Joplin/Jasper, Newton Counties CoC',
        'MO-603' => 'St. Joseph/Andrew, Buchanan, DeKalb Counties CoC',
        'MO-604' => 'Kansas City (MO&KS), Independence, Lee’s Summit/Jackson, Wyandotte Counties CoC',
        'MO-606' => 'Missouri Balance of State CoC',
        'MP-500' => 'Northern Mariana Islands CoC',
        'MS-500' => 'Jackson/Rankin, Madison Counties CoC',
        'MS-501' => 'Mississippi Balance of State CoC',
        'MS-503' => 'Gulf Port/Gulf Coast Regional CoC',
        'MT-500' => 'Montana Statewide CoC',
        'NC-500' => 'Winston-Salem/Forsyth County CoC',
        'NC-501' => 'Asheville/Buncombe County CoC',
        'NC-502' => 'Durham City & County CoC',
        'NC-503' => 'North Carolina Balance of State CoC',
        'NC-504' => 'Greensboro, High Point/Guilford County CoC',
        'NC-505' => 'Charlotte/Mecklenburg County CoC',
        'NC-506' => 'Wilmington/Brunswick, New Hanover, Pender Counties CoC',
        'NC-507' => 'Raleigh/Wake County CoC',
        'NC-509' => 'Gastonia/Cleveland, Gaston, Lincoln Counties CoC',
        'NC-511' => 'Fayetteville/Cumberland County CoC',
        'NC-513' => 'Chapel Hill/Orange County CoC',
        'NC-516' => 'Northwest North Carolina CoC',
        'ND-500' => 'North Dakota Statewide CoC',
        'NE-500' => 'Nebraska Balance of State CoC',
        'NE-501' => 'Omaha, Council Bluffs CoC',
        'NE-502' => 'Lincoln CoC',
        'NH-500' => 'New Hampshire Balance of State CoC',
        'NH-501' => 'Manchester CoC',
        'NH-502' => 'Nashua/Hillsborough County CoC',
        'NJ-500' => 'Atlantic City & County CoC',
        'NJ-501' => 'Bergen County CoC',
        'NJ-502' => 'Burlington County CoC',
        'NJ-503' => 'Camden City & County/Gloucester, Cape May, Cumberland Counties CoC',
        'NJ-504' => 'Newark/Essex County CoC',
        'NJ-506' => 'Jersey City, Bayonne/Hudson County CoC',
        'NJ-507' => 'New Brunswick/Middlesex County CoC',
        'NJ-508' => 'Monmouth County CoC',
        'NJ-509' => 'Morris County CoC',
        'NJ-510' => 'Lakewood Township/Ocean County CoC',
        'NJ-511' => 'Paterson/Passaic County CoC',
        'NJ-512' => 'Salem County CoC',
        'NJ-513' => 'Somerset County CoC',
        'NJ-514' => 'Trenton/Mercer County CoC',
        'NJ-515' => 'Elizabeth/Union County CoC',
        'NJ-516' => 'Warren, Sussex, Hunterdon Counties CoC',
        'NM-500' => 'Albuquerque CoC',
        'NM-501' => 'New Mexico Balance of State CoC',
        'NV-500' => 'Las Vegas/Clark County CoC',
        'NV-501' => 'Reno, Sparks/Washoe County CoC',
        'NV-502' => 'Nevada Balance of State CoC',
        'NY-500' => 'Rochester, Irondequoit, Greece/Monroe County CoC',
        'NY-501' => 'Elmira/Steuben, Allegany, Livingston, Chemung, Schuyler Counties CoC',
        'NY-503' => 'Albany City & County CoC',
        'NY-505' => 'Syracuse, Auburn/Onondaga, Oswego, Cayuga Counties CoC',
        'NY-507' => 'Schenectady City & County CoC',
        'NY-508' => 'Buffalo, Niagara Falls/Erie, Niagara, Orleans, Genesee, Wyoming Counties CoC',
        'NY-510' => 'Ithaca/Tompkins County CoC',
        'NY-511' => 'Binghamton, Union Town/Broome, Otsego, Chenango, Delaware, Cortland, Tioga Counties CoC',
        'NY-512' => 'Troy/Rensselaer County CoC',
        'NY-513' => 'Wayne, Ontario, Seneca, Yates Counties CoC',
        'NY-514' => 'Jamestown, Dunkirk/Chautauqua County CoC',
        'NY-518' => 'Utica, Rome/Oneida, Madison Counties CoC',
        'NY-519' => 'Columbia, Greene Counties CoC',
        'NY-520' => 'Franklin, Essex Counties CoC',
        'NY-522' => 'Jefferson, Lewis, St. Lawrence Counties CoC',
        'NY-523' => 'Glens Falls, Saratoga Springs/Saratoga, Washington, Warren, Hamilton Counties CoC',
        'NY-525' => 'New York Balance of State CoC',
        'NY-600' => 'New York City CoC',
        'NY-601' => 'Poughkeepsie/Dutchess County CoC',
        'NY-602' => 'Newburgh, Middletown/Orange County CoC',
        'NY-603' => 'Nassau, Suffolk Counties CoC',
        'NY-604' => 'Yonkers, Mount Vernon/Westchester County CoC',
        'NY-606' => 'Rockland County CoC',
        'NY-608' => 'Kingston/Ulster County CoC',
        'OH-500' => 'Cincinnati/Hamilton County CoC',
        'OH-501' => 'Toledo/Lucas County CoC',
        'OH-502' => 'Cleveland/Cuyahoga County CoC',
        'OH-503' => 'Columbus/Franklin County CoC',
        'OH-504' => 'Youngstown/Mahoning County CoC',
        'OH-505' => 'Dayton, Kettering/Montgomery County CoC',
        'OH-506' => 'Akron, Barberton/Summit County CoC',
        'OH-507' => 'Ohio Balance of State CoC',
        'OH-508' => 'Canton, Massillon, Alliance/Stark County CoC',
        'OK-500' => 'North Central Oklahoma CoC',
        'OK-501' => 'Tulsa City & County CoC',
        'OK-502' => 'Oklahoma City CoC',
        'OK-503' => 'Oklahoma Balance of State CoC',
        'OK-504' => 'Norman/Cleveland County CoC',
        'OK-505' => 'Northeast Oklahoma CoC',
        'OK-506' => 'Southwest Oklahoma Regional CoC',
        'OK-507' => 'Southeastern Oklahoma Regional CoC',
        'OR-500' => 'Eugene, Springfield/Lane County CoC',
        'OR-501' => 'Portland, Gresham/Multnomah County CoC',
        'OR-502' => 'Medford, Ashland/Jackson County CoC',
        'OR-503' => 'Central Oregon CoC',
        'OR-504' => 'Salem/Marion, Polk Counties CoC',
        'OR-505' => 'Oregon Balance of State CoC',
        'OR-506' => 'Hillsboro, Beaverton/Washington County CoC',
        'OR-507' => 'Clackamas County CoC',
        'PA-500' => 'Philadelphia CoC',
        'PA-501' => 'Harrisburg/Dauphin County CoC',
        'PA-502' => 'Upper Darby, Chester, Haverford/Delaware County CoC',
        'PA-503' => 'Wilkes-Barre, Hazleton/ Luzerne County CoC',
        'PA-504' => 'Lower Merion, Norristown, Abington/Montgomery County CoC',
        'PA-505' => 'Chester County CoC',
        'PA-506' => 'Reading/Berks County CoC',
        'PA-508' => 'Scranton/Lackawanna County CoC',
        'PA-509' => 'Eastern Pennsylvania CoC',
        'PA-510' => 'Lancaster City & County CoC',
        'PA-511' => 'Bristol, Bensalem/Bucks County CoC',
        'PA-512' => 'York City & County CoC',
        'PA-600' => 'Pittsburgh, McKeesport, Penn Hills/Allegheny County CoC',
        'PA-601' => 'Western Pennsylvania CoC',
        'PA-603' => 'Beaver County CoC',
        'PA-605' => 'Erie City & County CoC',
        'PR-502' => 'Puerto Rico Balance of Commonwealth CoC',
        'PR-503' => 'South-Southeast Puerto Rico CoC',
        'RI-500' => 'Rhode Island Statewide CoC',
        'SC-500' => 'Charleston/Low Country CoC',
        'SC-501' => 'Greenville, Anderson, Spartanburg/Upstate CoC',
        'SC-502' => 'Columbia/Midlands CoC',
        'SC-503' => 'Sumter City & County CoC',
        'SD-500' => 'South Dakota Statewide CoC',
        'TN-500' => 'Chattanooga/Southeast Tennessee CoC',
        'TN-501' => 'Memphis/Shelby County CoC',
        'TN-502' => 'Knoxville/Knox County CoC',
        'TN-503' => 'Central Tennessee CoC',
        'TN-504' => 'Nashville-Davidson County CoC',
        'TN-506' => 'Upper Cumberland CoC',
        'TN-507' => 'Jackson/West Tennessee CoC',
        'TN-509' => 'Appalachian Regional CoC',
        'TN-510' => 'Murfreesboro/Rutherford County CoC',
        'TN-512' => 'Morristown/Blount, Sevier, Campbell, Cocke Counties CoC',
        'TX-500' => 'San Antonio/Bexar County CoC',
        'TX-503' => 'Austin/Travis County CoC',
        'TX-600' => 'Dallas City & County, Irving CoC',
        'TX-601' => 'Fort Worth, Arlington/Tarrant County CoC',
        'TX-603' => 'El Paso City & County CoC',
        'TX-604' => 'Waco/McLennan County CoC',
        'TX-607' => 'Texas Balance of State CoC',
        'TX-611' => 'Amarillo CoC',
        'TX-624' => 'Wichita Falls/Wise, Palo Pinto, Wichita, Archer Counties CoC',
        'TX-700' => 'Houston, Pasadena, Conroe/Harris, Ft. Bend, Montgomery Counties CoC',
        'TX-701' => 'Bryan, College Station/Brazos Valley CoC',
        'UT-500' => 'Salt Lake City & County CoC',
        'UT-503' => 'Utah Balance of State CoC',
        'UT-504' => 'Provo/Mountainland CoC',
        'VA-500' => 'Richmond/Henrico, Chesterfield, Hanover Counties CoC',
        'VA-501' => 'Norfolk, Chesapeake, Suffolk/Isle of Wight, Southampton Counties CoC',
        'VA-502' => 'Roanoke City & County, Salem CoC',
        'VA-503' => 'Virginia Beach CoC',
        'VA-504' => 'Charlottesville CoC',
        'VA-505' => 'Newport News, Hampton/Virginia Peninsula CoC',
        'VA-507' => 'Portsmouth CoC',
        'VA-508' => 'Lynchburg CoC',
        'VA-513' => 'Harrisonburg, Winchester/Western Virginia CoC',
        'VA-514' => 'Fredericksburg/Spotsylvania, Stafford Counties CoC',
        'VA-521' => 'Virginia Balance of State CoC',
        'VA-600' => 'Arlington County CoC',
        'VA-601' => 'Fairfax County CoC',
        'VA-602' => 'Loudoun County CoC',
        'VA-603' => 'Alexandria CoC',
        'VA-604' => 'Prince William County CoC',
        'VI-500' => 'Virgin Islands CoC',
        'VT-500' => 'Vermont Balance of State CoC',
        'VT-501' => 'Burlington/Chittenden County CoC',
        'WA-500' => 'Seattle/King County CoC',
        'WA-501' => 'Washington Balance of State CoC',
        'WA-502' => 'Spokane City & County CoC',
        'WA-503' => 'Tacoma, Lakewood/Pierce County CoC',
        'WA-504' => 'Everett/Snohomish County CoC',
        'WA-508' => 'Vancouver/Clark County CoC',
        'WI-500' => 'Wisconsin Balance of State CoC',
        'WI-501' => 'Milwaukee City & County CoC',
        'WI-502' => 'Racine City & County CoC',
        'WI-503' => 'Madison/Dane County CoC',
        'WV-500' => 'Wheeling, Weirton Area CoC',
        'WV-501' => 'Huntington/Cabell, Wayne Counties CoC',
        'WV-503' => 'Charleston/Kanawha, Putnam, Boone, Clay Counties CoC',
        'WV-508' => 'West Virginia Balance of State CoC',
        'WY-500' => 'Wyoming Statewide CoC',
      }.freeze
    end

    def coc_codes(id, reverse = false, raise_on_missing: false)
      _translate(coc_codes_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.03.4
    def geography_types
      {
        1 => 'Urban',
        2 => 'Suburban',
        3 => 'Rural',
        99 => 'Unknown / data not collected',
      }.freeze
    end

    def geography_type(id, reverse = false, raise_on_missing: false)
      _translate(geography_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.06.1
    def funding_sources
      {
        1 => 'HUD: CoC - Homelessness Prevention (High Performing Communities Only)',
        2 => 'HUD: CoC - Permanent Supportive Housing',
        3 => 'HUD: CoC - Rapid Re-Housing',
        4 => 'HUD: CoC - Supportive Services Only',
        5 => 'HUD: CoC - Transitional Housing',
        6 => 'HUD: CoC - Safe Haven',
        7 => 'HUD: CoC - Single Room Occupancy (SRO)',
        8 => 'HUD: ESG - Emergency Shelter (operating and/or essential services)',
        9 => 'HUD: ESG - Homelessness Prevention',
        10 => 'HUD: ESG - Rapid Rehousing',
        11 => 'HUD: ESG - Street Outreach',
        12 => 'HUD: Rural Housing Stability Assistance Program [Deprecated]',
        13 => 'HUD: HOPWA - Hotel/Motel Vouchers',
        14 => 'HUD: HOPWA - Housing Information',
        15 => 'HUD: HOPWA - Permanent Housing (facility based or TBRA)',
        16 => 'HUD: HOPWA - Permanent Housing Placement',
        17 => 'HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance',
        18 => 'HUD: HOPWA - Short-Term Supportive Facility',
        19 => 'HUD: HOPWA - Transitional Housing (facility based or TBRA)',
        20 => 'HUD: HUD/VASH',
        21 => 'HHS: PATH - Street Outreach & Supportive Services Only',
        22 => 'HHS: RHY - Basic Center Program (prevention and shelter)',
        23 => 'HHS: RHY - Maternity Group Home for Pregnant and Parenting Youth',
        24 => 'HHS: RHY - Transitional Living Program',
        25 => 'HHS: RHY - Street Outreach Project',
        26 => 'HHS: RHY - Demonstration Project',
        27 => 'VA: CRS Contract Residential Services',
        30 => 'VA: Community Contract Safe Haven Program',
        32 => 'VA: Compensated Work Therapy Transitional Residence',
        33 => 'VA: Supportive Services for Veteran Families',
        34 => 'N/A',
        35 => 'HUD: Pay for Success',
        36 => 'HUD: Public and Indian Housing (PIH) Programs',
        37 => 'VA: Grant Per Diem - Bridge Housing',
        38 => 'VA: Grant Per Diem - Low Demand',
        39 => 'VA: Grant Per Diem - Hospital to Housing',
        40 => 'VA: Grant Per Diem - Clinical Treatment',
        41 => 'VA: Grant Per Diem - Service Intensive Transitional Housing',
        42 => 'VA: Grant Per Diem - Transition in Place',
        43 => 'HUD: CoC - Youth Homeless Demonstration Program (YHDP)',
        44 => 'HUD: CoC - Joint Component TH/RRH',
        45 => 'VA: Grant Per Diem - Case Management/Housing Retention',
        46 => 'Local or Other Funding Source',
        47 => 'HUD: ESG - CV',
        48 => 'HUD: HOPWA - CV',
        49 => 'HUD: CoC - Joint Component RRH/PSH [Deprecated]',
        50 => 'HUD: HOME',
        51 => 'HUD: HOME (ARP)',
        52 => 'HUD: PIH (Emergency Housing Voucher)',
        53 => 'HUD: ESG - RUSH',
        54 => 'HUD: Unsheltered Special NOFO',
        55 => 'HUD: Rural Special NOFO',
      }.freeze
    end

    def funding_source(id, reverse = false, raise_on_missing: false)
      _translate(funding_sources, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.07.4
    def household_types
      {
        1 => 'Households without children',
        3 => 'Households with at least one adult and one child',
        4 => 'Households with only children',
      }.freeze
    end

    def household_type(id, reverse = false, raise_on_missing: false)
      _translate(household_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.07.5
    def bed_types
      {
        1 => 'Facility-based',
        2 => 'Voucher',
        3 => 'Other',
      }.freeze
    end

    def bed_type(id, reverse = false, raise_on_missing: false)
      _translate(bed_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.07.6
    def availabilities
      {
        1 => 'Year-round',
        2 => 'Seasonal',
        3 => 'Overflow',
      }.freeze
    end

    def availability(id, reverse = false, raise_on_missing: false)
      _translate(availabilities, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 2.08.1
    def hmis_participation_types
      {
        0 => 'Not Participating',
        1 => 'HMIS Participating',
        2 => 'Comparable Database Participating',
      }.freeze
    end

    def hmis_participation_type(id, reverse = false, raise_on_missing: false)
      _translate(hmis_participation_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.01.5
    def name_data_quality_options
      {
        1 => 'Full name reported',
        2 => 'Partial, street name, or code name reported',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def name_data_quality(id, reverse = false, raise_on_missing: false)
      _translate(name_data_quality_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.02.2
    def ssn_data_quality_options
      {
        1 => 'Full SSN reported',
        2 => 'Approximate or partial SSN reported',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def ssn_data_quality(id, reverse = false, raise_on_missing: false)
      _translate(ssn_data_quality_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.03.2
    def dob_data_quality_options
      {
        1 => 'Full DOB reported',
        2 => 'Approximate or partial DOB reported',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def dob_data_quality(id, reverse = false, raise_on_missing: false)
      _translate(dob_data_quality_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.12
    def destinations
      {
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        17 => 'Other',
        24 => 'Deceased',
        30 => 'No exit interview completed',
        99 => 'Data not collected',
        101 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter',
        116 => 'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
        118 => 'Safe Haven',
        204 => 'Psychiatric hospital or other psychiatric facility',
        205 => 'Substance abuse treatment facility or detox center',
        206 => 'Hospital or other residential non-psychiatric medical facility',
        207 => 'Jail, prison or juvenile detention facility',
        215 => 'Foster care home or foster care group home',
        225 => 'Long-term care facility or nursing home',
        302 => 'Transitional housing for homeless persons (including homeless youth)',
        312 => 'Staying or living with family, temporary tenure (e.g. room, apartment or house)',
        313 => 'Staying or living with friends, temporary tenure (e.g. room apartment or house)',
        314 => 'Hotel or motel paid for without emergency shelter voucher',
        327 => 'Moved from one HOPWA funded project to HOPWA TH',
        329 => 'Residential project or halfway house with no homeless criteria',
        332 => 'Host Home (non-crisis)',
        410 => 'Rental by client, no ongoing housing subsidy',
        411 => 'Owned by client, no ongoing housing subsidy',
        421 => 'Owned by client, with ongoing housing subsidy',
        422 => 'Staying or living with family, permanent tenure',
        423 => 'Staying or living with friends, permanent tenure',
        426 => 'Moved from one HOPWA funded project to HOPWA PH',
        435 => 'Rental by client, with ongoing housing subsidy',
      }.freeze
    end

    def destination(id, reverse = false, raise_on_missing: false)
      _translate(destinations, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.12.A
    def rental_subsidy_types
      {
        428 => 'GPD TIP housing subsidy',
        419 => 'VASH housing subsidy',
        431 => 'RRH or equivalent subsidy',
        433 => 'HCV voucher (tenant or project based) (not dedicated)',
        434 => 'Public housing unit',
        420 => 'Rental by client, with other ongoing housing subsidy',
        436 => 'Housing Stability Voucher',
        437 => 'Family Unification Program Voucher (FUP)',
        438 => 'Foster Youth to Independence Initiative (FYI)',
        439 => 'Permanent Supportive Housing',
        440 => 'Other permanent housing dedicated for formerly homeless persons',
      }.freeze
    end

    def rental_subsidy_type(id, reverse = false, raise_on_missing: false)
      _translate(rental_subsidy_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.15.1
    def relationships_to_hoh
      {
        1 => 'Self (head of household)',
        2 => 'Child',
        3 => 'Spouse or partner',
        4 => 'Other relative',
        5 => 'Unrelated household member',
        99 => 'Data not collected',
      }.freeze
    end

    def relationship_to_hoh(id, reverse = false, raise_on_missing: false)
      _translate(relationships_to_hoh, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.6.1
    def genders
      {
        0 => 'Woman (Girl, if child)',
        1 => 'Man (Boy, if child)',
        2 => 'Culturally Specific Identity (e.g., Two-Spirit)',
        4 => 'Non-Binary',
        5 => 'Transgender',
        6 => 'Questioning',
        3 => 'Different Identity',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def gender(id, reverse = false, raise_on_missing: false)
      _translate(genders, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.917
    def prior_living_situations
      {
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
        101 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter',
        116 => 'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
        118 => 'Safe Haven',
        204 => 'Psychiatric hospital or other psychiatric facility',
        205 => 'Substance abuse treatment facility or detox center',
        206 => 'Hospital or other residential non-psychiatric medical facility',
        207 => 'Jail, prison or juvenile detention facility',
        215 => 'Foster care home or foster care group home',
        225 => 'Long-term care facility or nursing home',
        302 => 'Transitional housing for homeless persons (including homeless youth)',
        314 => 'Hotel or motel paid for without emergency shelter voucher',
        329 => 'Residential project or halfway house with no homeless criteria',
        332 => 'Host Home (non-crisis)',
        335 => 'Staying or living in a family member’s room, apartment, or house',
        336 => "Staying or living in a friend's room, apartment or house",
        410 => 'Rental by client, no ongoing housing subsidy',
        411 => 'Owned by client, no ongoing housing subsidy',
        421 => 'Owned by client, with ongoing housing subsidy',
        435 => 'Rental by client, with ongoing housing subsidy',
      }.freeze
    end

    def prior_living_situation(id, reverse = false, raise_on_missing: false)
      _translate(prior_living_situations, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.917.2
    def length_of_stays
      {
        2 => 'One week or more, but less than one month',
        3 => 'One month or more, but less than 90 days',
        4 => '90 days or more but less than one year',
        5 => 'One year or longer',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        10 => 'One night or less',
        11 => 'Two to six nights',
        99 => 'Data not collected',
      }.freeze
    end

    def residence_prior_length_of_stay(id, reverse = false, raise_on_missing: false)
      _translate(length_of_stays, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.917.4
    def times_homeless_options
      {
        1 => 'One time',
        2 => 'Two times',
        3 => 'Three times',
        4 => 'Four or more times',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def times_homeless_past_three_years(id, reverse = false, raise_on_missing: false)
      _translate(times_homeless_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 3.917.5
    def month_categories
      {
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
        101 => '1',
        102 => '2',
        103 => '3',
        104 => '4',
        105 => '5',
        106 => '6',
        107 => '7',
        108 => '8',
        109 => '9',
        110 => '10',
        111 => '11',
        112 => '12',
        113 => 'More than 12 months',
      }.freeze
    end

    def months_homeless_past_three_years(id, reverse = false, raise_on_missing: false)
      _translate(month_categories, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.04.A
    def reason_not_insureds
      {
        1 => 'Applied; decision pending',
        2 => 'Applied; client not eligible',
        3 => 'Client did not apply',
        4 => 'Insurance type N/A for this client',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def reason_not_insured(id, reverse = false, raise_on_missing: false)
      _translate(reason_not_insureds, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.10.2
    def disability_responses
      {
        0 => 'No',
        1 => 'Alcohol use disorder',
        2 => 'Drug use disorder',
        3 => 'Both alcohol and drug use disorders',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def disability_response(id, reverse = false, raise_on_missing: false)
      _translate(disability_responses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.11.A
    def when_occurreds
      {
        1 => 'Within the past three months',
        2 => 'Three to six months ago (excluding six months exactly)',
        3 => 'Six months to one year ago (excluding one year exactly)',
        4 => 'One year or more',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def when_d_v_occurred(id, reverse = false, raise_on_missing: false)
      _translate(when_occurreds, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.12
    def current_living_situations
      {
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        17 => 'Other',
        37 => 'Worker unable to determine',
        99 => 'Data not collected',
        101 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter',
        116 => 'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
        118 => 'Safe Haven',
        204 => 'Psychiatric hospital or other psychiatric facility',
        205 => 'Substance abuse treatment facility or detox center',
        206 => 'Hospital or other residential non-psychiatric medical facility',
        207 => 'Jail, prison or juvenile detention facility',
        215 => 'Foster care home or foster care group home',
        225 => 'Long-term care facility or nursing home',
        302 => 'Transitional housing for homeless persons (including homeless youth)',
        314 => 'Hotel or motel paid for without emergency shelter voucher',
        329 => 'Residential project or halfway house with no homeless criteria',
        332 => 'Host Home (non-crisis)',
        335 => 'Staying or living in a family member’s room, apartment, or house',
        336 => "Staying or living in a friend's room, apartment or house",
        410 => 'Rental by client, no ongoing housing subsidy',
        411 => 'Owned by client, no ongoing housing subsidy',
        421 => 'Owned by client, with ongoing housing subsidy',
        435 => 'Rental by client, with ongoing housing subsidy',
      }.freeze
    end

    def current_living_situation(id, reverse = false, raise_on_missing: false)
      _translate(current_living_situations, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.14
    def bed_night_options
      {
        200 => 'Bed Night',
      }.freeze
    end

    def bed_night(id, reverse = false, raise_on_missing: false)
      _translate(bed_night_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.19.3
    def assessment_types
      {
        1 => 'Phone',
        2 => 'Virtual',
        3 => 'In Person',
      }.freeze
    end

    def assessment_type(id, reverse = false, raise_on_missing: false)
      _translate(assessment_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.19.4
    def assessment_levels
      {
        1 => 'Crisis Needs Assessment',
        2 => 'Housing Needs Assessment',
      }.freeze
    end

    def assessment_level(id, reverse = false, raise_on_missing: false)
      _translate(assessment_levels, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.19.7
    def prioritization_statuses
      {
        1 => 'Placed on prioritization list',
        2 => 'Not placed on prioritization list',
      }.freeze
    end

    def prioritization_status(id, reverse = false, raise_on_missing: false)
      _translate(prioritization_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.20.2
    def events
      {
        1 => 'Referral to Prevention Assistance project',
        2 => 'Problem Solving/Diversion/Rapid Resolution intervention or service',
        3 => 'Referral to scheduled Coordinated Entry Crisis Needs Assessment',
        4 => 'Referral to scheduled Coordinated Entry Housing Needs Assessment',
        5 => 'Referral to Post-placement/ follow-up case management',
        6 => 'Referral to Street Outreach project or services',
        7 => 'Referral to Housing Navigation project or services',
        8 => 'Referral to Non-continuum services: Ineligible for continuum services',
        9 => 'Referral to Non-continuum services: No availability in continuum services',
        10 => 'Referral to Emergency Shelter bed opening',
        11 => 'Referral to Transitional Housing bed/unit opening',
        12 => 'Referral to Joint TH-RRH project/unit/resource opening',
        13 => 'Referral to RRH project resource opening',
        14 => 'Referral to PSH project resource opening',
        15 => 'Referral to Other PH project/unit/resource opening',
        16 => 'Referral to emergency assistance/flex fund/furniture assistance',
        17 => 'Referral to Emergency Housing Voucher (EHV)',
        18 => 'Referral to a Housing Stability Voucher',
      }.freeze
    end

    def event(id, reverse = false, raise_on_missing: false)
      _translate(events, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 4.20.D
    def referral_results
      {
        1 => 'Successful referral: client accepted',
        2 => 'Unsuccessful referral: client rejected',
        3 => 'Unsuccessful referral: provider rejected',
      }.freeze
    end

    def referral_result(id, reverse = false, raise_on_missing: false)
      _translate(referral_results, id, reverse, raise_on_missing: raise_on_missing)
    end

    # 5.03.1
    def data_collection_stages
      {
        1 => 'Project entry',
        2 => 'Update',
        3 => 'Project exit',
        5 => 'Annual assessment',
        6 => 'Post-exit',
      }.freeze
    end

    def data_collection_stage(id, reverse = false, raise_on_missing: false)
      _translate(data_collection_stages, id, reverse, raise_on_missing: raise_on_missing)
    end

    # C2.2
    def moving_on_assistance_options
      {
        1 => 'Subsidized housing application assistance',
        2 => 'Financial assistance for Moving On (e.g., security deposit, moving expenses)',
        3 => 'Non-financial assistance for Moving On (e.g., housing navigation, transition support)',
        4 => 'Housing referral/placement',
        5 => 'Other',
      }.freeze
    end

    def moving_on_assistance(id, reverse = false, raise_on_missing: false)
      _translate(moving_on_assistance_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # C3.2
    def current_school_attendeds
      {
        0 => 'Not currently enrolled in any school or educational course',
        1 => 'Currently enrolled but NOT attending regularly (when school or the course is in session)',
        2 => 'Currently enrolled and attending regularly (when school or the course is in session)',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def current_school_attended(id, reverse = false, raise_on_missing: false)
      _translate(current_school_attendeds, id, reverse, raise_on_missing: raise_on_missing)
    end

    # C3.A
    def most_recent_ed_statuses
      {
        0 => 'K12: Graduated from high school',
        1 => 'K12: Obtained GED',
        2 => 'K12: Dropped out',
        3 => 'K12: Suspended',
        4 => 'K12: Expelled',
        5 => 'Higher education: Pursuing a credential but not currently attending',
        6 => 'Higher education: Dropped out',
        7 => 'Higher education: Obtained a credential/degree',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def most_recent_ed_status(id, reverse = false, raise_on_missing: false)
      _translate(most_recent_ed_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # C3.B
    def current_ed_statuses
      {
        0 => 'Pursuing a high school diploma or GED',
        1 => "Pursuing Associate's Degree",
        2 => "Pursuing Bachelor's Degree",
        3 => 'Pursuing Graduate Degree',
        4 => 'Pursuing other post-secondary credential',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def current_ed_status(id, reverse = false, raise_on_missing: false)
      _translate(current_ed_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # C4.A
    def preferred_languages
      {
        100 => 'Acholi',
        101 => 'Afar',
        102 => 'Afrikaans',
        103 => 'Ahtna',
        104 => 'Akan',
        105 => 'Akateko',
        106 => 'Akuzipigestun / St. Lawrence Island Yupik (aka Siberian Yupik)',
        107 => 'Albanian',
        108 => 'Algonquian',
        109 => 'Alutiiq',
        110 => 'American Sign Language',
        111 => 'Amharic',
        112 => 'Anuak',
        113 => 'Apache',
        114 => 'Arabic',
        115 => 'Armenian',
        116 => 'Assyrian',
        117 => 'Atnakenaege’ / Ahtna',
        118 => 'Aymara',
        119 => 'Azerbaijani',
        120 => 'Bahasa',
        121 => 'Bahdini',
        122 => 'Bajuni',
        123 => 'Bambara',
        124 => 'Bantu',
        125 => 'Barese',
        126 => 'Basque',
        127 => 'Bassa',
        128 => 'Belorussian',
        129 => 'Bemba',
        130 => 'Benaadir',
        131 => 'Bengali',
        132 => 'Berber',
        133 => 'Black American Sign Language',
        134 => 'Bosnian',
        135 => 'Bravanese',
        136 => 'Bulgarian',
        137 => 'Burmese',
        138 => 'Cambodian',
        139 => 'Cantonese',
        140 => 'Cape Verdean Creole',
        141 => 'Catalan',
        142 => 'Cebuano',
        143 => 'Central Alaskan Yup’ik / Yugtun',
        144 => 'Chaldean',
        145 => 'Chamorro',
        146 => 'Chaochow',
        147 => 'Cherokee',
        148 => 'Chinese',
        149 => 'Chipewyan',
        150 => 'Choctaw',
        151 => 'Chuukese',
        152 => 'Cree',
        153 => 'Croatian',
        154 => 'Czech',
        155 => 'Dakota',
        156 => 'Danish',
        157 => 'Dari',
        158 => 'Deg Xinag',
        159 => "Dena'inaq' / Dena'ina",
        160 => "Denaakk'e / Koyukon",
        161 => 'Dewoin',
        162 => "Dinak'i / Upper Kuskokwim",
        163 => "Dinjii Zhuh K'yaa / Gwich'in",
        164 => 'Dinka',
        165 => 'Doogh Qinaq / Holikachuk',
        166 => 'Duala',
        167 => 'Dutch',
        168 => 'Dzongkha',
        169 => 'Edo',
        170 => 'Ekegusli',
        171 => 'English',
        172 => 'Estonian',
        173 => 'Ewe',
        174 => 'Eyak',
        175 => 'Farsi',
        176 => 'Fijian',
        177 => 'Filipino',
        178 => 'Finnish',
        179 => 'Flemish',
        180 => 'French',
        181 => 'French Cajun',
        182 => 'French Canadian',
        183 => 'French Creole',
        184 => 'French Haitian',
        185 => 'Fukienese',
        186 => 'Fulani',
        187 => 'Fuzhou',
        188 => 'Ga',
        189 => 'Gaddang',
        190 => 'Gaelic',
        191 => 'Garre',
        192 => 'Gen',
        193 => 'Georgian',
        194 => 'German',
        195 => 'Gheg',
        196 => 'Gokana',
        197 => 'Greek',
        198 => 'Gujarati',
        199 => 'Gulay',
        200 => 'Gullah',
        201 => 'Gurani',
        202 => "Gwich'in",
        203 => 'Haida',
        204 => 'Haitian',
        205 => 'Haitian Creole',
        206 => 'Hakka',
        207 => 'Häl golan / Hän',
        208 => 'Hassaniyya',
        209 => 'Hausa',
        210 => "Hawai'i Sign Language",
        211 => 'Hawaiian',
        212 => 'Hebrew',
        213 => 'Hiligaynon',
        214 => 'Hindi',
        215 => 'Hindko',
        216 => 'Hmong',
        217 => 'Hokkien',
        218 => 'Holikachuk',
        219 => 'Hopi',
        220 => 'Huanese',
        221 => 'Hungarian',
        222 => 'Ibanag',
        223 => 'Icelandic',
        224 => 'Igbo',
        225 => 'Ilocano',
        226 => 'Indonesian',
        227 => 'Inuktitut',
        228 => 'Inupiatun / Inupiaq',
        229 => 'Italian',
        230 => 'Jakartanese',
        231 => 'Jamaican Patois',
        232 => 'Japanese',
        233 => 'Jarai',
        234 => 'Javanese',
        235 => 'Jingpho',
        236 => 'Jinyu',
        237 => 'Juba Arabic',
        238 => 'Jula',
        239 => 'Kaba',
        240 => 'Kamba',
        241 => 'Kam Muang',
        242 => 'Kanjobal',
        243 => 'Kannada',
        244 => 'Karen',
        245 => 'Kashmiri',
        246 => 'Kayah',
        247 => 'Kazakh',
        248 => 'Keresan',
        249 => 'Keresan Sign Language',
        250 => 'Kham',
        251 => 'Khana',
        252 => 'Khmer',
        253 => "K'iche'",
        254 => 'Kikuyu',
        255 => 'Kimiiru',
        256 => 'Kinyarwanda',
        257 => 'Kiowa',
        258 => 'Koho',
        259 => 'Korean',
        260 => 'Koyukon',
        261 => 'Krahn',
        262 => 'Krio',
        263 => 'Kunama',
        264 => 'Kurmanji',
        265 => 'Kyrgyz',
        266 => 'Lakota',
        267 => 'Laotian',
        268 => 'Latvian',
        269 => 'Liberian Pidgin English',
        270 => 'Lingala',
        271 => 'Lingít / Tlingit',
        272 => 'Lithuanian',
        273 => 'Lombard',
        274 => 'Luba-Kasai',
        275 => 'Luganda',
        276 => 'Luo',
        277 => 'Maay',
        278 => 'Macedonian',
        279 => 'Malay',
        280 => 'Malayalam',
        281 => 'Maltese',
        282 => 'Mam',
        283 => 'Mandarin',
        284 => 'Mandinka',
        285 => 'Maninka',
        286 => 'Manobo',
        287 => 'Marathi',
        288 => 'Marka',
        289 => 'Marshallese',
        290 => 'Masalit',
        291 => 'Mbay',
        292 => 'Mien',
        293 => 'Mirpuri',
        294 => 'Mixteco',
        295 => 'Mizo',
        296 => 'Mnong',
        297 => 'Mongolian',
        298 => 'Montenegrin',
        299 => 'Moroccan Arabic',
        300 => 'Mortlockese',
        301 => 'Muscogee',
        302 => 'Napoletano',
        303 => 'Navajo',
        304 => 'Navajo Family Sign',
        305 => 'Ndebele',
        306 => 'Neapolitan',
        307 => 'Nee’aandeg’ / Tanacross',
        308 => 'Nepali',
        309 => 'Ngambay',
        310 => 'Nigerian Pidgin',
        311 => 'Northern Sotho',
        312 => 'Norwegian',
        313 => 'Nuer',
        314 => 'Nupe',
        315 => 'Nyanja',
        316 => 'Nyoro',
        317 => "O'odham",
        318 => 'Ojibwe',
        319 => 'Oromo',
        320 => 'Pampangan',
        321 => 'Papiamento',
        322 => 'Pashto',
        323 => 'Pennsylvania Dutch',
        324 => 'Persian',
        325 => 'Plains Sign Language',
        326 => 'Plateau Sign Language',
        327 => 'Plautdietsch',
        328 => 'Pohnpeian',
        329 => 'Polish',
        330 => 'Portuguese',
        331 => 'Portuguese Brazilian',
        332 => 'Portuguese Cape Verdean',
        333 => 'Portuguese Creole',
        334 => 'Puerto Rican Sign Language',
        335 => 'Pugliese',
        336 => 'Pulaar',
        337 => 'Punjabi',
        338 => 'Putian',
        339 => 'Quechua',
        340 => 'Quichua',
        341 => 'Rade',
        342 => 'Rakhine',
        343 => 'Rohingya',
        344 => 'Romanian',
        345 => 'Kirundi',
        346 => 'Russian',
        347 => 'Samoan',
        348 => 'Samoan Sign Language',
        349 => 'Sango',
        350 => 'Seraiki',
        351 => 'Serbian',
        352 => 'Shanghainese',
        353 => 'Shona',
        354 => 'Sichuan Yi',
        355 => 'Sicilian',
        356 => 'Sindhi',
        357 => 'Sinhalese',
        358 => 'Sioux',
        359 => 'Slovak',
        360 => 'Slovenian',
        361 => 'Sm’algyax / (Coast) Tsimshian',
        362 => 'Soga',
        363 => 'Somali',
        364 => 'Soninke',
        365 => 'Sorani',
        366 => 'Sothern Sotho',
        367 => 'Spanish',
        368 => 'Spanish Creole',
        369 => 'Sudanese Arabic',
        370 => 'Sugpiaq / Alutiiq',
        371 => 'Sunda',
        372 => 'Susu',
        373 => 'Swahili',
        374 => 'Swati',
        375 => 'Swedish',
        376 => 'Sylhetti',
        377 => 'Tagalog',
        378 => 'Taiwanese',
        379 => 'Tajik',
        380 => 'Tamil',
        381 => 'Tanacross',
        382 => 'Tanana',
        383 => 'Telugu',
        384 => 'Thai',
        385 => 'Tibetan',
        386 => 'Tigre',
        387 => 'Tigrigna',
        388 => 'Tlingit',
        389 => 'Toishanese',
        390 => 'Tongan',
        391 => 'Tooro',
        392 => 'Trique',
        393 => 'Tsimshian',
        394 => 'Tsonga',
        395 => 'Tswana',
        396 => 'Turkish',
        397 => 'Turkmen',
        398 => 'Twi',
        399 => 'Tzotzil',
        400 => 'Ukrainian',
        401 => 'Unangam Tunuu / Aleutian Aleut',
        402 => 'Upper Kuskokwim',
        403 => 'Urdu',
        404 => 'Uyghur',
        405 => 'Uzbek',
        406 => 'Venda',
        407 => 'Vietnamese',
        408 => 'Visayan',
        409 => 'Welsh',
        410 => 'Wodaabe',
        411 => 'Wolof',
        412 => 'Wuzhou',
        413 => 'Xaat Kíl / Haida',
        414 => 'Xhosa',
        415 => 'Xiang',
        416 => 'Yemeni Arabic',
        417 => 'Yiddish',
        418 => 'Yoruba',
        419 => 'Yunnanese',
        420 => 'Yupik',
        421 => 'Zapoteco',
        422 => 'Zarma',
        423 => 'Zo',
        424 => 'Zulu',
        425 => 'Zuni',
        426 => 'Zyphe',
        21 => 'Different preferred language',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def preferred_language(id, reverse = false, raise_on_missing: false)
      _translate(preferred_languages, id, reverse, raise_on_missing: raise_on_missing)
    end

    # P1.2
    def path_services_options
      {
        1 => 'Re-engagement',
        2 => 'Screening',
        3 => 'Habilitation/rehabilitation',
        4 => 'Community mental health',
        5 => 'Substance use treatment',
        6 => 'Case management',
        7 => 'Residential supportive services',
        8 => 'Housing minor renovation',
        9 => 'Housing moving assistance',
        10 => 'Housing eligibility determination',
        11 => 'Security deposits',
        12 => 'One-time rent for eviction prevention',
        14 => 'Clinical assessment',
      }.freeze
    end

    def path_services(id, reverse = false, raise_on_missing: false)
      _translate(path_services_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # P2.2
    def path_referral_options
      {
        1 => 'Community mental health',
        2 => 'Substance use treatment',
        3 => 'Primary health/dental care',
        4 => 'Job training',
        5 => 'Educational services',
        6 => 'Housing services',
        7 => 'Permanent housing',
        8 => 'Income assistance',
        9 => 'Employment assistance',
        10 => 'Medical insurance',
        11 => 'Temporary housing',
      }.freeze
    end

    def path_referral(id, reverse = false, raise_on_missing: false)
      _translate(path_referral_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # P2.A
    def path_referral_outcomes
      {
        1 => 'Attained',
        2 => 'Not attained',
        3 => 'Unknown',
      }.freeze
    end

    def path_referral_outcome(id, reverse = false, raise_on_missing: false)
      _translate(path_referral_outcomes, id, reverse, raise_on_missing: raise_on_missing)
    end

    # P3.A
    def reason_not_enrolleds
      {
        1 => 'Client was found ineligible for PATH',
        2 => 'Client was not enrolled for other reason(s)',
        3 => 'Unable to locate client',
      }.freeze
    end

    def reason_not_enrolled(id, reverse = false, raise_on_missing: false)
      _translate(reason_not_enrolleds, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R1.1
    def referral_sources
      {
        1 => 'Self-referral',
        2 => 'Individual: Parent/Guardian/Relative/Friend/Foster Parent/Other Individual',
        7 => 'Outreach Project',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        11 => 'Temporary Shelter',
        18 => 'Residential Project',
        28 => 'Hotline',
        30 => 'Child Welfare/CPS',
        34 => 'Juvenile Justice',
        35 => 'Law Enforcement/Police',
        37 => 'Mental Hospital',
        38 => 'School',
        39 => 'Other organization',
        99 => 'Data not collected',
      }.freeze
    end

    def referral_source(id, reverse = false, raise_on_missing: false)
      _translate(referral_sources, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R11.A
    def rhy_numberof_years_options
      {
        1 => 'Less than one year',
        2 => '1 to 2 years',
        3 => '3 to 5 or more years',
        99 => 'Data not collected',
      }.freeze
    end

    def rhy_numberof_years(id, reverse = false, raise_on_missing: false)
      _translate(rhy_numberof_years_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R14.2
    def rhy_services_options
      {
        2 => 'Community service/service learning (CSL)',
        5 => 'Education',
        6 => 'Employment and training services',
        7 => 'Criminal justice /legal services',
        8 => 'Life skills training',
        10 => 'Parenting education for youth with children',
        12 => 'Post-natal care for client (person who gave birth)',
        13 => 'Pre-natal care',
        14 => 'Health/medical care',
        17 => 'Substance use disorder treatment',
        18 => 'Substance use disorder/Prevention Services',
        26 => 'Home-based Services',
        27 => 'Post-natal newborn care (wellness exams; immunizations)',
        28 => 'STD Testing',
        29 => 'Street-based Services',
      }.freeze
    end

    def rhy_services(id, reverse = false, raise_on_missing: false)
      _translate(rhy_services_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R15.B
    def count_exchange_for_sexes
      {
        1 => '1-3',
        2 => '4-7',
        3 => '8-11',
        4 => '12 or more',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def count_exchange_for_sex(id, reverse = false, raise_on_missing: false)
      _translate(count_exchange_for_sexes, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R17.1
    def project_completion_statuses
      {
        1 => 'Completed project',
        2 => 'Client voluntarily left early',
        3 => 'Client was expelled or otherwise involuntarily discharged from project',
      }.freeze
    end

    def project_completion_status(id, reverse = false, raise_on_missing: false)
      _translate(project_completion_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R17.A
    def early_exit_reasons
      {
        1 => 'Left for other opportunities - independent living',
        2 => 'Left for other opportunities - education',
        3 => 'Left for other opportunities - military',
        4 => 'Left for other opportunities - other',
        5 => 'Needs could not be met by project',
      }.freeze
    end

    def early_exit_reason(id, reverse = false, raise_on_missing: false)
      _translate(early_exit_reasons, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R17.A
    def expelled_reasons
      {
        1 => 'Criminal activity/destruction of property/violence',
        2 => 'Non-compliance with project rules',
        3 => 'Non-payment of rent/occupancy charge',
        4 => 'Reached maximum time allowed by project',
        5 => 'Project terminated',
        6 => 'Unknown/disappeared',
      }.freeze
    end

    def expelled_reason(id, reverse = false, raise_on_missing: false)
      _translate(expelled_reasons, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R19.A
    def worker_responses
      {
        0 => 'No',
        1 => 'Yes',
        2 => 'Worker does not know',
      }.freeze
    end

    def worker_response(id, reverse = false, raise_on_missing: false)
      _translate(worker_responses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R2.A
    def reason_no_services_options
      {
        1 => 'Out of age range',
        2 => 'Ward of the state',
        3 => 'Ward of the criminal justice system',
        4 => 'Other',
        99 => 'Data not collected',
      }.freeze
    end

    def reason_no_services(id, reverse = false, raise_on_missing: false)
      _translate(reason_no_services_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R20.2
    def aftercare_provideds
      {
        0 => 'No',
        1 => 'Yes',
        9 => 'Client prefers not to answer',
      }.freeze
    end

    def aftercare_provided(id, reverse = false, raise_on_missing: false)
      _translate(aftercare_provideds, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R3.1
    def sexual_orientations
      {
        1 => 'Heterosexual',
        2 => 'Gay',
        3 => 'Lesbian',
        4 => 'Bisexual',
        5 => 'Questioning / unsure',
        6 => 'Other',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def sexual_orientation(id, reverse = false, raise_on_missing: false)
      _translate(sexual_orientations, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R4.1
    def last_grade_completeds
      {
        1 => 'Less than grade 5',
        2 => 'Grades 5-6',
        3 => 'Grades 7-8',
        4 => 'Grades 9-11',
        5 => 'Grade 12',
        6 => 'School program does not have grade levels',
        7 => 'GED',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        10 => 'Some college',
        11 => "Associate's degree",
        12 => "Bachelor's degree",
        13 => 'Graduate degree',
        14 => 'Vocational certification',
        99 => 'Data not collected',
      }.freeze
    end

    def last_grade_completed(id, reverse = false, raise_on_missing: false)
      _translate(last_grade_completeds, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R5.1
    def school_statuses
      {
        1 => 'Attending school regularly',
        2 => 'Attending school irregularly',
        3 => 'Graduated from high school',
        4 => 'Obtained GED',
        5 => 'Dropped out',
        6 => 'Suspended',
        7 => 'Expelled',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def school_status(id, reverse = false, raise_on_missing: false)
      _translate(school_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R6.A
    def employment_types
      {
        1 => 'Full-time',
        2 => 'Part-time',
        3 => 'Seasonal / sporadic (including day labor)',
        99 => 'Data not collected',
      }.freeze
    end

    def employment_type(id, reverse = false, raise_on_missing: false)
      _translate(employment_types, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R6.B
    def not_employed_reasons
      {
        1 => 'Looking for work',
        2 => 'Unable to work',
        3 => 'Not looking for work',
        99 => 'Data not collected',
      }.freeze
    end

    def not_employed_reason(id, reverse = false, raise_on_missing: false)
      _translate(not_employed_reasons, id, reverse, raise_on_missing: raise_on_missing)
    end

    # R7.1
    def health_statuses
      {
        1 => 'Excellent',
        2 => 'Very good',
        3 => 'Good',
        4 => 'Fair',
        5 => 'Poor',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def health_status(id, reverse = false, raise_on_missing: false)
      _translate(health_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V1.11
    def military_branches
      {
        1 => 'Army',
        2 => 'Air Force',
        3 => 'Navy',
        4 => 'Marines',
        6 => 'Coast Guard',
        7 => 'Space Force',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def military_branch(id, reverse = false, raise_on_missing: false)
      _translate(military_branches, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V1.12
    def discharge_statuses
      {
        1 => 'Honorable',
        2 => 'General under honorable conditions',
        4 => 'Bad conduct',
        5 => 'Dishonorable',
        6 => 'Under other than honorable conditions (OTH)',
        7 => 'Uncharacterized',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def discharge_status(id, reverse = false, raise_on_missing: false)
      _translate(discharge_statuses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V2.2
    def ssvf_services_options
      {
        1 => 'Outreach services',
        2 => 'Case management services',
        3 => 'Assistance obtaining VA benefits',
        4 => 'Assistance obtaining/coordinating other public benefits',
        5 => 'Direct provision of other public benefits',
        6 => 'Other (non-TFA) supportive service approved by VA',
        7 => 'Shallow Subsidy',
        8 => 'Returning Home',
        9 => 'Rapid Resolution',
      }.freeze
    end

    def ssvf_services(id, reverse = false, raise_on_missing: false)
      _translate(ssvf_services_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V2.3
    def hopwa_financial_assistance_options
      {
        1 => 'Rental assistance',
        2 => 'Security deposits',
        3 => 'Utility deposits',
        4 => 'Utility payments',
        7 => 'Mortgage assistance',
      }.freeze
    end

    def hopwa_financial_assistance(id, reverse = false, raise_on_missing: false)
      _translate(hopwa_financial_assistance_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V2.A
    def ssvf_sub_type3s
      {
        1 => 'VA vocational and rehabilitation counseling',
        2 => 'Employment and training services',
        3 => 'Educational assistance',
        4 => 'Health care services',
      }.freeze
    end

    def ssvf_sub_type3(id, reverse = false, raise_on_missing: false)
      _translate(ssvf_sub_type3s, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V2.B
    def ssvf_sub_type4s
      {
        1 => 'Health care services',
        2 => 'Daily living services',
        3 => 'Personal financial planning services',
        4 => 'Transportation services',
        5 => 'Income support services',
        6 => 'Fiduciary and representative payee services',
        7 => 'Legal services - child support',
        8 => 'Legal services - eviction prevention',
        9 => 'Legal services - outstanding fines and penalties',
        10 => "Legal services - restore / acquire driver's license",
        11 => 'Legal services - other',
        12 => 'Child care',
        13 => 'Housing counseling',
      }.freeze
    end

    def ssvf_sub_type4(id, reverse = false, raise_on_missing: false)
      _translate(ssvf_sub_type4s, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V2.C
    def ssvf_sub_type5s
      {
        1 => 'Personal financial planning services',
        2 => 'Transportation services',
        3 => 'Income support services',
        4 => 'Fiduciary and representative payee services',
        5 => 'Legal services - child support',
        6 => 'Legal services - eviction prevention',
        7 => 'Legal services - outstanding fines and penalties',
        8 => "Legal services - restore / acquire driver's license",
        9 => 'Legal services - other',
        10 => 'Child care',
        11 => 'Housing counseling',
      }.freeze
    end

    def ssvf_sub_type5(id, reverse = false, raise_on_missing: false)
      _translate(ssvf_sub_type5s, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V3.3
    def ssvf_financial_assistance_options
      {
        1 => 'Rental assistance',
        2 => 'Security deposit',
        3 => 'Utility deposit',
        4 => 'Utility fee payment assistance',
        5 => 'Moving costs',
        8 => 'Transportation services: tokens/vouchers',
        9 => 'Transportation services: vehicle repair/maintenance',
        10 => 'Child care',
        11 => 'General housing stability assistance - emergency supplies [Deprecated]',
        12 => 'General housing stability assistance',
        14 => 'Emergency housing assistance',
        15 => 'Shallow Subsidy - Financial Assistance',
        16 => 'Food Assistance',
        17 => 'Landlord Incentive',
        18 => 'Tenant Incentive',
      }.freeze
    end

    def ssvf_financial_assistance(id, reverse = false, raise_on_missing: false)
      _translate(ssvf_financial_assistance_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V4.1
    def percent_amis
      {
        1 => '30% or less',
        2 => '31% to 50%',
        3 => '51% to 80%',
        4 => '81% or greater',
        99 => 'Data not collected',
      }.freeze
    end

    def percent_ami(id, reverse = false, raise_on_missing: false)
      _translate(percent_amis, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V6.1
    def vamc_station_numbers
      {
        402 => '(402) Togus, ME',
        405 => '(405) White River Junction, VT',
        436 => '(436) Montana HCS',
        437 => '(437) Fargo, ND',
        438 => '(438) Sioux Falls, SD',
        442 => '(442) Cheyenne, WY',
        459 => '(459) Honolulu, HI',
        460 => '(460) Wilmington, DE',
        463 => '(463) Anchorage, AK',
        501 => '(501) New Mexico HCS',
        502 => '(502) Alexandria, LA',
        503 => '(503) Altoona, PA',
        504 => '(504) Amarillo, TX',
        506 => '(506) Ann Arbor, MI',
        508 => '(508) Atlanta, GA',
        509 => '(509) Augusta, GA',
        512 => '(512) Baltimore HCS, MD',
        515 => '(515) Battle Creek, MI',
        516 => '(516) Bay Pines, FL',
        517 => '(517) Beckley, WV',
        518 => '(518) Bedford, MA',
        519 => '(519) Big Spring, TX',
        520 => '(520) Gulf Coast HCS, MS',
        521 => '(521) Birmingham, AL',
        523 => '(523) VA Boston HCS, MA',
        526 => '(526) Bronx, NY',
        528 => '(528) Western New York, NY',
        529 => '(529) Butler, PA',
        531 => '(531) Boise, ID',
        534 => '(534) Charleston, SC',
        537 => '(537) Jesse Brown VAMC (Chicago), IL',
        538 => '(538) Chillicothe, OH',
        539 => '(539) Cincinnati, OH',
        540 => '(540) Clarksburg, WV',
        541 => '(541) Cleveland, OH',
        542 => '(542) Coatesville, PA',
        544 => '(544) Columbia, SC',
        546 => '(546) Miami, FL',
        548 => '(548) West Palm Beach, FL',
        549 => '(549) Dallas, TX',
        550 => '(550) Danville, IL',
        552 => '(552) Dayton, OH',
        553 => '(553) Detroit, MI',
        554 => '(554) Denver, CO',
        556 => '(556) Captain James A Lovell FHCC',
        557 => '(557) Dublin, GA',
        558 => '(558) Durham, NC',
        561 => '(561) New Jersey HCS, NJ',
        562 => '(562) Erie, PA',
        564 => '(564) Fayetteville, AR',
        565 => '(565) Fayetteville, NC',
        568 => '(568) Black Hills HCS, SD',
        570 => '(570) Fresno, CA',
        573 => '(573) Gainesville, FL',
        575 => '(575) Grand Junction, CO',
        578 => '(578) Hines, IL',
        580 => '(580) Houston, TX',
        581 => '(581) Huntington, WV',
        583 => '(583) Indianapolis, IN',
        585 => '(585) Iron Mountain, MI',
        586 => '(586) Jackson, MS',
        589 => '(589) Kansas City, MO',
        590 => '(590) Hampton, VA',
        593 => '(593) Las Vegas, NV',
        595 => '(595) Lebanon, PA',
        596 => '(596) Lexington, KY',
        598 => '(598) Little Rock, AR',
        600 => '(600) Long Beach, CA',
        603 => '(603) Louisville, KY',
        605 => '(605) Loma Linda, CA',
        607 => '(607) Madison, WI',
        608 => '(608) Manchester, NH',
        610 => '(610) Northern Indiana HCS, IN',
        612 => '(612) N. California, CA',
        613 => '(613) Martinsburg, WV',
        614 => '(614) Memphis, TN',
        618 => '(618) Minneapolis, MN',
        619 => '(619) Central Alabama Veterans HCS, AL',
        620 => '(620) VA Hudson Valley HCS, NY',
        621 => '(621) Mountain Home, TN',
        623 => '(623) Muskogee, OK',
        626 => '(626) Middle Tennessee HCS, TN',
        629 => '(629) New Orleans, LA',
        630 => '(630) New York Harbor HCS, NY',
        631 => '(631) VA Central Western Massachusetts HCS',
        632 => '(632) Northport, NY',
        635 => '(635) Oklahoma City, OK',
        636 => '(636) Nebraska-W Iowa, NE',
        637 => '(637) Asheville, NC',
        640 => '(640) Palo Alto, CA',
        642 => '(642) Philadelphia, PA',
        644 => '(644) Phoenix, AZ',
        646 => '(646) Pittsburgh, PA',
        648 => '(648) Portland, OR',
        649 => '(649) Northern Arizona HCS',
        650 => '(650) Providence, RI',
        652 => '(652) Richmond, VA',
        653 => '(653) Roseburg, OR',
        654 => '(654) Reno, NV',
        655 => '(655) Saginaw, MI',
        656 => '(656) St. Cloud, MN',
        657 => '(657) St. Louis, MO',
        658 => '(658) Salem, VA',
        659 => '(659) Salisbury, NC',
        660 => '(660) Salt Lake City, UT',
        662 => '(662) San Francisco, CA',
        663 => '(663) VA Puget Sound, WA',
        664 => '(664) San Diego, CA',
        666 => '(666) Sheridan, WY',
        667 => '(667) Shreveport, LA',
        668 => '(668) Spokane, WA',
        671 => '(671) San Antonio, TX',
        672 => '(672) San Juan, PR',
        673 => '(673) Tampa, FL',
        674 => '(674) Temple, TX',
        675 => '(675) Orlando, FL',
        676 => '(676) Tomah, WI',
        678 => '(678) Southern Arizona HCS',
        679 => '(679) Tuscaloosa, AL',
        687 => '(687) Walla Walla, WA',
        688 => '(688) Washington, DC',
        689 => '(689) VA Connecticut HCS, CT',
        691 => '(691) Greater Los Angeles HCS',
        692 => '(692) White City, OR',
        693 => '(693) Wilkes-Barre, PA',
        695 => '(695) Milwaukee, WI',
        740 => '(740) VA Texas Valley Coastal Bend HCS',
        756 => '(756) El Paso, TX',
        757 => '(757) Columbus, OH',
        '459GE' => '(459GE) Guam',
        '528A5' => '(528A5) Canandaigua, NY',
        '528A6' => '(528A6) Bath, NY',
        '528A7' => '(528A7) Syracuse, NY',
        '528A8' => '(528A8) Albany, NY',
        '589A4' => '(589A4) Columbia, MO',
        '589A5' => '(589A5) Kansas City, MO',
        '589A6' => '(589A6) Eastern KS HCS, KS',
        '589A7' => '(589A7) Wichita, KS',
        '636A6' => '(636A6) Central Iowa, IA',
        '636A8' => '(636A8) Iowa City, IA',
        '657A4' => '(657A4) Poplar Bluff, MO',
        '657A5' => '(657A5) Marion, IL',
        99 => 'Data not collected',
      }.freeze
    end

    def vamc_station_number(id, reverse = false, raise_on_missing: false)
      _translate(vamc_station_numbers, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.1
    def no_points_yes_options
      {
        0 => 'No (0 points)',
        1 => 'Yes',
        99 => 'Data not collected',
      }.freeze
    end

    def no_points_yes(id, reverse = false, raise_on_missing: false)
      _translate(no_points_yes_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.A
    def time_to_housing_losses
      {
        0 => '1-6 days',
        1 => '7-13 days',
        2 => '14-21 days',
        3 => 'More than 21 days',
        99 => 'Data not collected',
      }.freeze
    end

    def time_to_housing_loss(id, reverse = false, raise_on_missing: false)
      _translate(time_to_housing_losses, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.B
    def annual_percent_amis
      {
        0 => '$0 (i.e., not employed, not receiving cash benefits, no other current income)',
        1 => '1-14% of Area Median Income (AMI) for household size',
        2 => '15-30% of AMI for household size',
        3 => 'More than 30% of AMI for household size',
        99 => 'Data not collected',
      }.freeze
    end

    def annual_percent_ami(id, reverse = false, raise_on_missing: false)
      _translate(annual_percent_amis, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.C
    def literal_homeless_histories
      {
        0 => 'Most recent episode occurred in the last year',
        1 => 'Most recent episode occurred more than one year ago',
        2 => 'None',
        99 => 'Data not collected',
      }.freeze
    end

    def literal_homeless_history(id, reverse = false, raise_on_missing: false)
      _translate(literal_homeless_histories, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.G
    def eviction_histories
      {
        0 => 'No prior rental evictions',
        1 => '1 prior rental eviction',
        2 => '2 or more prior rental evictions',
        99 => 'Data not collected',
      }.freeze
    end

    def eviction_history(id, reverse = false, raise_on_missing: false)
      _translate(eviction_histories, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.I
    def incarcerated_adults
      {
        0 => 'Not incarcerated',
        1 => 'Incarcerated once',
        2 => 'Incarcerated two or more times',
        99 => 'Data not collected',
      }.freeze
    end

    def incarcerated_adult(id, reverse = false, raise_on_missing: false)
      _translate(incarcerated_adults, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V7.O
    def dependent_under_6_options
      {
        0 => 'No',
        1 => 'Youngest child is under 1 year old',
        2 => 'Youngest child is 1 to 6 years old and/or one or more children (any age) require significant care',
        99 => 'Data not collected',
      }.freeze
    end

    def dependent_under_6(id, reverse = false, raise_on_missing: false)
      _translate(dependent_under_6_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V8.1
    def voucher_tracking_options
      {
        1 => 'Referral package forwarded to PHA',
        2 => 'Voucher denied by PHA',
        3 => 'Voucher issued by PHA',
        4 => 'Voucher revoked or expired',
        5 => 'Voucher in use - veteran moved into housing',
        6 => 'Voucher was ported locally',
        7 => 'Voucher was administratively absorbed by new PHA',
        8 => 'Voucher was converted to Housing Choice Voucher',
        9 => 'Veteran exited - voucher was returned',
        10 => 'Veteran exited - family maintained the voucher',
        11 => 'Veteran exited - prior to ever receiving a voucher',
        12 => 'Other',
      }.freeze
    end

    def voucher_tracking(id, reverse = false, raise_on_missing: false)
      _translate(voucher_tracking_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # V9.1
    def cm_exit_reasons
      {
        1 => 'Accomplished goals and/or obtained services and no longer needs CM',
        2 => 'Transferred to another HUD/VASH program site',
        3 => 'Found/chose other housing',
        4 => 'Did not comply with HUD/VASH CM',
        5 => 'Eviction and/or other housing related issues',
        6 => 'Unhappy with HUD/VASH housing',
        7 => 'No longer financially eligible for HUD/VASH voucher',
        8 => 'No longer interested in participating in this program',
        9 => 'Veteran cannot be located',
        10 => 'Veteran too ill to participate at this time',
        11 => 'Veteran is incarcerated',
        12 => 'Veteran is deceased',
        13 => 'Other',
      }.freeze
    end

    def cm_exit_reason(id, reverse = false, raise_on_missing: false)
      _translate(cm_exit_reasons, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W1.2
    def hopwa_services_options
      {
        1 => 'Adult day care and personal assistance',
        2 => 'Case management',
        3 => 'Child care',
        4 => 'Criminal justice/legal services',
        5 => 'Education',
        6 => 'Employment and training services',
        7 => 'Food/meals/nutritional services',
        8 => 'Health/medical care',
        9 => 'Life skills training',
        10 => 'Mental health care/counseling',
        11 => 'Outreach and/or engagement',
        12 => 'Substance use services/treatment',
        13 => 'Transportation',
        14 => 'Other HOPWA funded service',
      }.freeze
    end

    def hopwa_services(id, reverse = false, raise_on_missing: false)
      _translate(hopwa_services_options, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W3
    def no_assistance_reasons
      {
        1 => 'Applied; decision pending',
        2 => 'Applied; client not eligible',
        3 => 'Client did not apply',
        4 => 'Insurance type not applicable for this client',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def no_assistance_reason(id, reverse = false, raise_on_missing: false)
      _translate(no_assistance_reasons, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W4.3
    def viral_load_availables
      {
        0 => 'Not available',
        1 => 'Available',
        2 => 'Undetectable',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def viral_load_available(id, reverse = false, raise_on_missing: false)
      _translate(viral_load_availables, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W4.B
    def t_cell_source_viral_load_sources
      {
        1 => 'Medical Report',
        2 => 'Client Report',
        3 => 'Other',
      }.freeze
    end

    def t_cell_source_viral_load_source(id, reverse = false, raise_on_missing: false)
      _translate(t_cell_source_viral_load_sources, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W5.1
    def housing_assessment_at_exits
      {
        1 => 'Able to maintain the housing they had at project entry',
        2 => 'Moved to new housing unit',
        3 => 'Moved in with family/friends on a temporary basis',
        4 => 'Moved in with family/friends on a permanent basis',
        5 => 'Moved to a transitional or temporary housing facility or program',
        6 => 'Client became homeless - moving to a shelter or other place unfit for human habitation',
        7 => 'Jail/prison',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        10 => 'Deceased',
        99 => 'Data not collected',
      }.freeze
    end

    def housing_assessment_at_exit(id, reverse = false, raise_on_missing: false)
      _translate(housing_assessment_at_exits, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W5.A
    def subsidy_information_as
      {
        1 => 'Without a subsidy',
        2 => 'With the subsidy they had at project entry',
        3 => 'With an on-going subsidy acquired since project entry',
        4 => 'Only with financial assistance other than a subsidy',
      }.freeze
    end

    def subsidy_information_a(id, reverse = false, raise_on_missing: false)
      _translate(subsidy_information_as, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W5.AB
    def subsidy_informations
      {
        1 => 'Without a subsidy',
        2 => 'With the subsidy they had at project entry',
        3 => 'With an on-going subsidy acquired since project entry',
        4 => 'Only with financial assistance other than a subsidy',
        11 => 'With on-going subsidy',
        12 => 'Without an on-going subsidy',
      }.freeze
    end

    def subsidy_information(id, reverse = false, raise_on_missing: false)
      _translate(subsidy_informations, id, reverse, raise_on_missing: raise_on_missing)
    end

    # W5.B
    def subsidy_information_bs
      {
        11 => 'With on-going subsidy',
        12 => 'Without an on-going subsidy',
      }.freeze
    end

    def subsidy_information_b(id, reverse = false, raise_on_missing: false)
      _translate(subsidy_information_bs, id, reverse, raise_on_missing: raise_on_missing)
    end

    # ad_hoc_yes_no
    def ad_hoc_yes_nos
      {
        0 => 'No',
        1 => 'Yes',
        8 => "Don't Know",
        9 => 'Prefers not to answer',
        99 => 'Data not collected',
      }.freeze
    end

    def ad_hoc_yes_no(id, reverse = false, raise_on_missing: false)
      _translate(ad_hoc_yes_nos, id, reverse, raise_on_missing: raise_on_missing)
    end

    # race
    def race_field_name_to_description
      {
        'AmIndAKNative' => 'American Indian, Alaska Native, or Indigenous',
        'Asian' => 'Asian or Asian American',
        'BlackAfAmerican' => 'Black, African American, or African',
        'NativeHIPacific' => 'Native Hawaiian or Pacific Islander',
        'White' => 'White',
        'HispanicLatinaeo' => 'Hispanic/Latina/e/o',
        'MidEastNAfrican' => 'Middle Eastern or North African',
        'RaceNone' => "Doesn't know, prefers not to answer, or not collected",
      }.freeze
    end

    def race(id, reverse = false, raise_on_missing: false)
      _translate(race_field_name_to_description, id, reverse, raise_on_missing: raise_on_missing)
    end
  end
end
