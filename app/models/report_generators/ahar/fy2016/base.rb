# Notes: see https://www.pivotaltracker.com/file_attachments/68760691/download for spec
# For each of the SUB_TYPES we need to answer the GLOBAL_QUESTIONS and the specific questions.
# In addition, we need to answer the summary questions as their own category
# 
# In Rails console: 
# load 'app/models/report_generators/ahar/fy2016/ahar.rb'
# answers = ReportGenerators::Ahar::Fy2016::Base.new.run!

# Definitions
# LTS: Long Term Stayers - 180 days within report range
# 
# HMIS terms
# http://www.hudhdx.info/Resources/Vendors/4_0/docs/HUD_HMIS_xsd.html
# 

module ReportGenerators::Ahar::Fy2016
  class Base
    include ArelHelper
    PH = [3,9,10,13] # Per Jennifer Flynn @ DND 2016 AHAR includes all 4
    TH = [2]
    ES = [1] 
    ADULT = 18
    REPORT_START = '2016-09-30'
    REPORT_END = '2015-10-01'
    SUB_TYPES = ['ES-FAM', 'ES-IND', 'PSH-FAM', 'PSH-IND', 'TH-FAM', 'TH-IND']
    GLOBAL_QUESTIONS = ['Age_LT_1', 'Age_Mx', 'Age_1_5', 'Age_6_12', 'Age_13_17', 'Age_18_24', 'Age_25_30', 'Age_31_50', 'Age_51_61', 'Age_62_GE', 'A_F_Nt_Mx', 'A_F_Nt_1_7', 'A_F_Nt_8_30', 'A_F_Nt_31_60', 'A_F_Nt_61_90', 'A_F_Nt_91_120', 'A_F_Nt_121_150', 'A_F_Nt_151_180', 'A_F_Nt_181_210', 'A_F_Nt_211_240', 'A_F_Nt_241_270', 'A_F_Nt_271_300', 'A_F_Nt_301_330', 'A_F_Nt_331_360', 'A_F_Nt_361_365', 'A_Mx_Gnd_Nt_Mx', 'A_Mx_Gnd_Nt_1_7', 'A_Mx_Gnd_Nt_8_30', 'A_Mx_Gnd_Nt_31_60', 'A_Mx_Gnd_Nt_61_90', 'A_Mx_Gnd_Nt_91_120', 'A_Mx_Gnd_Nt_121_150', 'A_Mx_Gnd_Nt_151_180', 'A_Mx_Gnd_Nt_181_210', 'A_Mx_Gnd_Nt_211_240', 'A_Mx_Gnd_Nt_241_270', 'A_Mx_Gnd_Nt_271_300', 'A_Mx_Gnd_Nt_301_330', 'A_Mx_Gnd_Nt_331_360', 'A_Mx_Gnd_Nt_361_365', 'A_M_Nt_Mx', 'A_M_Nt_1_7', 'A_M_Nt_8_30', 'A_M_Nt_31_60', 'A_M_Nt_61_90', 'A_M_Nt_91_120', 'A_M_Nt_121_150', 'A_M_Nt_151_180', 'A_M_Nt_181_210', 'A_M_Nt_211_240', 'A_M_Nt_241_270', 'A_M_Nt_271_300', 'A_M_Nt_301_330', 'A_M_Nt_331_360', 'A_M_Nt_361_365', 'Beds_Avail_April_Ngt', 'Beds_Avail_Avg_Ngt', 'Beds_Avail_Jan_Ngt', 'Beds_Avail_Jul_Ngt', 'Beds_Avail_Oct_Ngt', 'Beds_nH', 'Beds_H', 'C_F_Nt_Mx', 'C_F_Nt_1_7', 'C_F_Nt_8_30', 'C_F_Nt_31_60', 'C_F_Nt_61_90', 'C_F_Nt_91_120', 'C_F_Nt_121_150', 'C_F_Nt_151_180', 'C_F_Nt_181_210', 'C_F_Nt_211_240', 'C_F_Nt_241_270', 'C_F_Nt_271_300', 'C_F_Nt_301_330', 'C_F_Nt_331_360', 'C_F_Nt_361_365', 'C_Mx_Gnd_Nt_Mx', 'C_Mx_Gnd_Nt_1_7', 'C_Mx_Gnd_Nt_8_30', 'C_Mx_Gnd_Nt_31_60', 'C_Mx_Gnd_Nt_61_90', 'C_Mx_Gnd_Nt_91_120', 'C_Mx_Gnd_Nt_121_150', 'C_Mx_Gnd_Nt_151_180', 'C_Mx_Gnd_Nt_181_210', 'C_Mx_Gnd_Nt_211_240', 'C_Mx_Gnd_Nt_241_270', 'C_Mx_Gnd_Nt_271_300', 'C_Mx_Gnd_Nt_301_330', 'C_Mx_Gnd_Nt_331_360', 'C_Mx_Gnd_Nt_361_365', 'C_M_Nt_Mx', 'C_M_Nt_1_7', 'C_M_Nt_8_30', 'C_M_Nt_31_60', 'C_M_Nt_61_90', 'C_M_Nt_91_120', 'C_M_Nt_121_150', 'C_M_Nt_151_180', 'C_M_Nt_181_210', 'C_M_Nt_211_240', 'C_M_Nt_241_270', 'C_M_Nt_271_300', 'C_M_Nt_301_330', 'C_M_Nt_331_360', 'C_M_Nt_361_365', 'Disabled_Mx', 'Disabled_No', 'Disabled_Yes', 'Ethn_His_Lat', 'Ethn_Mx', 'Ethn_NHis_NLat', 'Gnd_A_F', 'Gnd_A_M', 'Gnd_A_Mx', 'Gnd_A_Oth', 'Gnd_A_TFM', 'Gnd_A_TMF', 'Gnd_C_F', 'Gnd_C_M', 'Gnd_C_Mx', 'Gnd_C_Oth', 'Gnd_C_TFM', 'Gnd_C_TMF', 'HH_Size_Mx', 'HH_Size_1', 'HH_Size_2', 'HH_Size_3', 'HH_Size_4', 'HH_Size_5_GE', 'HH_Typ_Mx', 'Lst_Res_Mx', 'Lst_Res_Zip_I', 'Lst_Res_Zip_NI', 'Lvn_B4_Prg_Ent_ES', 'Lvn_B4_Prg_Ent_Fam', 'Lvn_B4_Prg_Ent_Foster', 'Lvn_B4_Prg_Ent_Fren', 'Lvn_B4_Prg_Ent_Hotel', 'Lvn_B4_Prg_Ent_Hsptl', 'Lvn_B4_Prg_Ent_Jail', 'Lvn_B4_Prg_Ent_Mx', 'Lvn_B4_Prg_Ent_N_4_Hbt', 'Lvn_B4_Prg_Ent_Oth', 'Lvn_B4_Prg_Ent_Own_NS', 'Lvn_B4_Prg_Ent_Own_S', 'Lvn_B4_Prg_Ent_Psych', 'Lvn_B4_Prg_Ent_PSH', 'Lvn_B4_Prg_Ent_Rent_NS', 'Lvn_B4_Prg_Ent_Rent_Oth_S', 'Lvn_B4_Prg_Ent_Rent_VS', 'Lvn_B4_Prg_Ent_SAbse', 'Lvn_B4_Prg_Ent_SH', 'Lvn_B4_Prg_Ent_TH', 'NVet', 'Pers_Apr_Ngt', 'Pers_Avg_Ngt', 'Pers_Jan_Ngt', 'Pers_Jul_Ngt', 'Pers_Multi_H', 'Pers_Oct_Ngt', 'Race_Amer_Ind_Alask', 'Race_Asian', 'Race_Black', 'Race_Multi', 'Race_Mx', 'Race_Nat_Haw_Oth_Pac', 'Race_Wh_His_Lat', 'Race_Wh_NHis_NLat', 'Stb_Prv_Nt_G_Wk_L_Mnt', 'Stb_Prv_Nt_G_3_Mt_L_Yr', 'Stb_Prv_Nt_Mx', 'Stb_Prv_Nt_1_Wk_LE', 'Stb_Prv_Nt_1_Yr_GE', 'Stb_Prv_Nt_1_3_Mnt', 'Undup_Pers_H', 'Vet', 'Vet_Mx']
    ES_FAMILY_QUESTIONS = ['Lts_Age_LT_1', 'Lts_Age_Mx', 'Lts_Age_1_5', 'Lts_Age_6_12', 'Lts_Age_13_17', 'Lts_Age_18_30', 'Lts_Age_31_50', 'Lts_Age_51_GE', 'Lts_Disabled_Mx', 'Lts_Disabled_No', 'Lts_Disabled_Yes', 'Lts_Ethn_His_Lat', 'Lts_Ethn_Mx', 'Lts_Ethn_NHis_NLat', 'Lts_HH_Size_Mx', 'Lts_HH_Size_1', 'Lts_HH_Size_2', 'Lts_HH_Size_3', 'Lts_HH_Size_4', 'Lts_HH_Size_5_GE', 'Lts_Nvet', 'Lts_Race_Amer_Ind_Alask', 'Lts_Race_Asian', 'Lts_Race_Black', 'Lts_Race_Multi', 'Lts_Race_Mx', 'Lts_Race_Nat_Haw_Oth_Pac', 'Lts_Race_Wh_His_Lat', 'Lts_Race_Wh_NHis_NLat', 'Lts_Vet', 'Lts_Vet_Mx', 'HH_Typ_A_Fam_C', 'HH_Typ_C_Fam_A', 'HHs', 'HHs_Apr_Ngt', 'HHs_Jan_Ngt', 'HHs_Jul_Ngt', 'HHs_Oct_Ngt']
    PSH_FAMILY_QUESTIONS = ['HH_Typ_A_Fam_C', 'HH_Typ_C_Fam_A', 'HHs', 'HHs_Apr_Ngt', 'HHs_Jan_Ngt', 'HHs_Jul_Ngt', 'HHs_Oct_Ngt', 'Pers_Dest_Exit_D', 'Pers_Dest_Exit_ES', 'Pers_Dest_Exit_Fam_Perm', 'Pers_Dest_Exit_Fam_Temp', 'Pers_Dest_Exit_Foster', 'Pers_Dest_Exit_Fren_Temp', 'Pers_Dest_Exit_Fren_Perm', 'Pers_Dest_Exit_Hotel', 'Pers_Dest_Exit_Hsptl', 'Pers_Dest_Exit_Jail', 'Pers_Dest_Exit_Mx', 'Pers_Dest_Exit_N_4_Hbt', 'Pers_Dest_Exit_Oth', 'Pers_Dest_Exit_Own_NS', 'Pers_Dest_Exit_Own_WS', 'Pers_Dest_Exit_Psych', 'Pers_Dest_Exit_PSH', 'Pers_Dest_Exit_Rent_NS', 'Pers_Dest_Exit_Rent_Oth_S', 'Pers_Dest_Exit_Rent_VS', 'Pers_Dest_Exit_SAbse', 'Pers_Dest_Exit_SH', 'Pers_Dest_Exit_TH', 'Pers_Disability_Dev_Dis', 'Pers_Disability_HIV_AIDS', 'Pers_Disability_Ment_Health', 'Pers_Disability_Ment_Health_and_Sub_Abuse', 'Pers_Disability_MX', 'Pers_Disability_Phys_Dis', 'Pers_Disability_Sub_Abuse', 'Pers_Entered_PSH', 'Pers_Exited_PSH', 'Pers_PSH_also_ES_IND', 'Pers_PSH_also_ES_FAM', 'Pers_PSH_also_TH_IND', 'Pers_PSH_also_TH_FAM', 'Pers_Rct_A_F_Nts_1_180', 'Pers_Rct_A_F_Nts_181_365', 'Pers_Rct_A_F_Nts_366_545', 'Pers_Rct_A_F_Nts_546_730', 'Pers_Rct_A_F_Nts_731_1825', 'Pers_Rct_A_F_Nts_1826_GE', 'Pers_Rct_A_F_Nts_MX', 'Pers_Rct_A_M_Nts_1_180', 'Pers_Rct_A_M_Nts_181_365', 'Pers_Rct_A_M_Nts_366_545', 'Pers_Rct_A_M_Nts_546_730', 'Pers_Rct_A_M_Nts_731_1825', 'Pers_Rct_A_M_Nts_1826_GE', 'Pers_Rct_A_M_Nts_MX', 'Pers_Rct_A_MX_Nts_1_180', 'Pers_Rct_A_MX_Nts_181_365', 'Pers_Rct_A_MX_Nts_366_545', 'Pers_Rct_A_MX_Nts_546_730', 'Pers_Rct_A_MX_Nts_731_1825', 'Pers_Rct_A_MX_Nts_1826_GE', 'Pers_Rct_A_MX_Nts_MX', 'Pers_Rct_C_F_Nts_1_180', 'Pers_Rct_C_F_Nts_181_365', 'Pers_Rct_C_F_Nts_366_545', 'Pers_Rct_C_F_Nts_546_730', 'Pers_Rct_C_F_Nts_731_1825', 'Pers_Rct_C_F_Nts_1826_GE', 'Pers_Rct_C_F_Nts_MX', 'Pers_Rct_C_M_Nts_1_180', 'Pers_Rct_C_M_Nts_181_365', 'Pers_Rct_C_M_Nts_366_545', 'Pers_Rct_C_M_Nts_546_730', 'Pers_Rct_C_M_Nts_731_1825', 'Pers_Rct_C_M_Nts_1826_GE', 'Pers_Rct_C_M_Nts_MX', 'Pers_Rct_C_MX_Nts_1_180', 'Pers_Rct_C_MX_Nts_181_365', 'Pers_Rct_C_MX_Nts_366_545', 'Pers_Rct_C_MX_Nts_546_730', 'Pers_Rct_C_MX_Nts_731_1825', 'Pers_Rct_C_MX_Nts_1826_GE', 'Pers_Rct_C_MX_Nts_MX', 'Pers_PSH_FAM_also_PSH_IND']
    TH_FAMILY_QUESTIONS = ['HH_Typ_A_Fam_C', 'HH_Typ_C_Fam_A', 'HHs', 'HHs_Apr_Ngt', 'HHs_Jan_Ngt', 'HHs_Jul_Ngt', 'HHs_Oct_Ngt']
    ES_INDIVIDUAL_QUESTIONS = ['Lts_Age_LT_1', 'Lts_Age_Mx', 'Lts_Age_1_5', 'Lts_Age_6_12', 'Lts_Age_13_17', 'Lts_Age_18_30', 'Lts_Age_31_50', 'Lts_Age_51_GE', 'Lts_Disabled_Mx', 'Lts_Disabled_No', 'Lts_Disabled_Yes', 'Lts_Ethn_His_Lat', 'Lts_Ethn_Mx', 'Lts_Ethn_NHis_NLat', 'Lts_HH_Size_Mx', 'Lts_HH_Size_1', 'Lts_HH_Size_2', 'Lts_HH_Size_3', 'Lts_HH_Size_4', 'Lts_HH_Size_5_GE', 'Lts_Nvet', 'Lts_Race_Amer_Ind_Alask', 'Lts_Race_Asian', 'Lts_Race_Black', 'Lts_Race_Multi', 'Lts_Race_Mx', 'Lts_Race_Nat_Haw_Oth_Pac', 'Lts_Race_Wh_His_Lat', 'Lts_Race_Wh_NHis_NLat', 'Lts_Vet', 'Lts_Vet_Mx', 'HH_Typ_Ind_A_F', 'HH_Typ_Ind_A_M', 'HH_Typ_A_Only', 'HH_Typ_C_Only', 'HH_Typ_UY']
    PSH_INDIVIDUAL_QUESTIONS = ['Pers_Dest_Exit_D', 'Pers_Dest_Exit_ES', 'Pers_Dest_Exit_Fam_Perm', 'Pers_Dest_Exit_Fam_Temp', 'Pers_Dest_Exit_Foster', 'Pers_Dest_Exit_Fren_Temp', 'Pers_Dest_Exit_Fren_Perm', 'Pers_Dest_Exit_Hotel', 'Pers_Dest_Exit_Hsptl', 'Pers_Dest_Exit_Jail', 'Pers_Dest_Exit_Mx', 'Pers_Dest_Exit_N_4_Hbt', 'Pers_Dest_Exit_Oth', 'Pers_Dest_Exit_Own_NS', 'Pers_Dest_Exit_Own_WS', 'Pers_Dest_Exit_Psych', 'Pers_Dest_Exit_PSH', 'Pers_Dest_Exit_Rent_NS', 'Pers_Dest_Exit_Rent_Oth_S', 'Pers_Dest_Exit_Rent_VS', 'Pers_Dest_Exit_SAbse', 'Pers_Dest_Exit_SH', 'Pers_Dest_Exit_TH', 'Pers_Disability_Dev_Dis', 'Pers_Disability_HIV_AIDS', 'Pers_Disability_Ment_Health', 'Pers_Disability_Ment_Health_and_Sub_Abuse', 'Pers_Disability_MX', 'Pers_Disability_Phys_Dis', 'Pers_Disability_Sub_Abuse', 'Pers_Entered_PSH', 'Pers_Exited_PSH', 'Pers_PSH_also_ES_IND', 'Pers_PSH_also_ES_FAM', 'Pers_PSH_also_TH_IND', 'Pers_PSH_also_TH_FAM', 'Pers_Rct_A_F_Nts_1_180', 'Pers_Rct_A_F_Nts_181_365', 'Pers_Rct_A_F_Nts_366_545', 'Pers_Rct_A_F_Nts_546_730', 'Pers_Rct_A_F_Nts_731_1825', 'Pers_Rct_A_F_Nts_1826_GE', 'Pers_Rct_A_F_Nts_MX', 'Pers_Rct_A_M_Nts_1_180', 'Pers_Rct_A_M_Nts_181_365', 'Pers_Rct_A_M_Nts_366_545', 'Pers_Rct_A_M_Nts_546_730', 'Pers_Rct_A_M_Nts_731_1825', 'Pers_Rct_A_M_Nts_1826_GE', 'Pers_Rct_A_M_Nts_MX', 'Pers_Rct_A_MX_Nts_1_180', 'Pers_Rct_A_MX_Nts_181_365', 'Pers_Rct_A_MX_Nts_366_545', 'Pers_Rct_A_MX_Nts_546_730', 'Pers_Rct_A_MX_Nts_731_1825', 'Pers_Rct_A_MX_Nts_1826_GE', 'Pers_Rct_A_MX_Nts_MX', 'Pers_Rct_C_F_Nts_1_180', 'Pers_Rct_C_F_Nts_181_365', 'Pers_Rct_C_F_Nts_366_545', 'Pers_Rct_C_F_Nts_546_730', 'Pers_Rct_C_F_Nts_731_1825', 'Pers_Rct_C_F_Nts_1826_GE', 'Pers_Rct_C_F_Nts_MX', 'Pers_Rct_C_M_Nts_1_180', 'Pers_Rct_C_M_Nts_181_365', 'Pers_Rct_C_M_Nts_366_545', 'Pers_Rct_C_M_Nts_546_730', 'Pers_Rct_C_M_Nts_731_1825', 'Pers_Rct_C_M_Nts_1826_GE', 'Pers_Rct_C_M_Nts_MX', 'Pers_Rct_C_MX_Nts_1_180', 'Pers_Rct_C_MX_Nts_181_365', 'Pers_Rct_C_MX_Nts_366_545', 'Pers_Rct_C_MX_Nts_546_730', 'Pers_Rct_C_MX_Nts_731_1825', 'Pers_Rct_C_MX_Nts_1826_GE', 'Pers_Rct_C_MX_Nts_MX', 'HH_Typ_Ind_A_F', 'HH_Typ_Ind_A_M', 'HH_Typ_A_Only', 'HH_Typ_C_Only', 'HH_Typ_UY', 'Pers_PSH_IND_also_PSH_FAM']
    TH_INDIVIDUAL_QUESTIONS = ['HH_Typ_Ind_A_F', 'HH_Typ_Ind_A_M', 'HH_Typ_A_Only', 'HH_Typ_C_Only', 'HH_Typ_UY']
    SUMMARY_QUESTIONS = ['Pers_all_4_Prog', 'Pers_only_EF', 'Pers_only_EF_TF', 'Pers_only_EF_TI', 'Pers_only_EF_TI_TF', 'Pers_only_EI', 'Pers_only_EI_EF_TF', 'Pers_only_EI_EF', 'Pers_only_EI_EF_TI', 'Pers_only_EI_TF', 'Pers_only_EI_TI', 'Pers_only_EI_TI_TF', 'Pers_only_TF', 'Pers_only_TI', 'Pers_only_TI_TF', 'Yr_Rnd_EF_Beds', 'Yr_Rnd_EF_U', 'Yr_Rnd_EI_Beds', 'Yr_Rnd_Eqv_EF_Beds', 'Yr_Rnd_Eqv_EI_Beds', 'Yr_Rnd_ES_Oflow_Vch', 'Yr_Rnd_ES_Ssnl', 'Yr_Rnd_TF_Beds', 'Yr_Rnd_TF_U', 'Yr_Rnd_TI_Beds', 'Yr_Rnd_PSH_Fam_Beds', 'Yr_Rnd_PSH_Fam_U', 'Yr_Rnd_PSH_Ind_Beds']

    COC_ZIP_CODES = [
      '02108', '02109', '02110', '02111', '02112', '02113', '02114', '02115', '02116', '02117', '02118', '02119', '02120', '02121', '02122', '02123', '02124', '02125', '02126', '02127', '02128', '02129', '02130', '02131', '02132', '02133', '02134', '02135', '02136', '02137', '02163', '02196', '02199', '02201', '02203', '02204', '02205', '02206', '02207', '02210', '02211', '02212', '02215', '02216', '02217', '02222', '02228', '02241', '02266', '02283', '02284', '02293', '02295', '02297', '02298',
    ]
    CENSUS_DATES = {
      "Oct_Ngt" => '2015-10-28',
      "Jan_Ngt" => '2016-01-27',
      "Apr_Ngt" => '2016-04-27',
      "Jul_Ngt" => '2016-08-27',
    }
    def self.questions
      all_specific_questions = GLOBAL_QUESTIONS + ES_FAMILY_QUESTIONS + ES_INDIVIDUAL_QUESTIONS + TH_FAMILY_QUESTIONS + TH_INDIVIDUAL_QUESTIONS + PSH_FAMILY_QUESTIONS + PSH_INDIVIDUAL_QUESTIONS + SUMMARY_QUESTIONS
      whitelist = (SUB_TYPES + ['Summary']).map{|m| {m => all_specific_questions}}
    end

    def report_class
      Reports::Ahar::Fy2016::Base
    end

    def vets_only
      false
    end

    def run!
      # allow report start to be set via options in sub-classes
      @report_start ||= '2016-09-30'
      @report_end ||= '2015-10-01'
      # Find the first queued report
      report = ReportResult.where(report: report_class.first).where(percent_complete: 0, job_status: nil).first
      return unless report.present? 
      Rails.logger.info "Starting report #{report.report.name}"
      report.update(percent_complete: 0.01)

      @answers = (SUB_TYPES).map{|m| [m, GLOBAL_QUESTIONS.map{|n| [n, 0]}.to_h]}.to_h
      @answers['ES-FAM'].merge!(ES_FAMILY_QUESTIONS.map{|n| [n, 0]}.to_h)
      @answers['ES-IND'].merge!(ES_INDIVIDUAL_QUESTIONS.map{|n| [n, 0]}.to_h)
      @answers['TH-FAM'].merge!(TH_FAMILY_QUESTIONS.map{|n| [n, 0]}.to_h)
      @answers['TH-IND'].merge!(TH_INDIVIDUAL_QUESTIONS.map{|n| [n, 0]}.to_h)
      @answers['PSH-FAM'].merge!(PSH_FAMILY_QUESTIONS.map{|n| [n, 0]}.to_h)
      @answers['PSH-IND'].merge!(PSH_INDIVIDUAL_QUESTIONS.map{|n| [n, 0]}.to_h)
      @answers['Summary'] = {}
      @answers['Summary'].merge!(SUMMARY_QUESTIONS.map{|n| [n, 0]}.to_h)

      @support = (SUB_TYPES).map{|m| [m, GLOBAL_QUESTIONS.map{|n| [n, {}]}.to_h]}.to_h
      @support['ES-FAM'].merge!(ES_FAMILY_QUESTIONS.map{|n| [n, {}]}.to_h)
      @support['ES-IND'].merge!(ES_INDIVIDUAL_QUESTIONS.map{|n| [n, {}]}.to_h)
      @support['TH-FAM'].merge!(TH_FAMILY_QUESTIONS.map{|n| [n, {}]}.to_h)
      @support['TH-IND'].merge!(TH_INDIVIDUAL_QUESTIONS.map{|n| [n, {}]}.to_h)
      @support['PSH-FAM'].merge!(PSH_FAMILY_QUESTIONS.map{|n| [n, {}]}.to_h)
      @support['PSH-IND'].merge!(PSH_INDIVIDUAL_QUESTIONS.map{|n| [n, {}]}.to_h)
      @support['Summary'] = {}
      @support['Summary'].merge!(SUMMARY_QUESTIONS.map{|n| [n, {}]}.to_h)

      @validations = {}

      answer_methods = [
        :add_age_answers,
        :add_length_of_stay_answers,
        :add_disability_answers,
        :add_ethnicity_answers,
        :add_gender_answers,
        :add_household_answers,
        :add_prior_living_situation_answers,
        :add_veteran_answers,
        :add_specific_date_answers,
        :add_average_night_answers,
        :add_multi_use_answers,
        :add_race_answers,
        :add_prior_living_length_answers,
        :add_unduplicated_count_answers,
        # sub-type specific
        :add_lts_answers,
        :add_family_answers,
        :add_household_date_answers,
        :add_individual_household_type_answers, # ES, TH, PSH
        # :add_psh_destination_answers, # individual and family
        :add_psh_disabilities, # individual and family
        :add_psh_entry_exit_answers, # individual and family
        :add_psh_also_other_project_type_answers, # individual and family
        :add_psh_most_recent_stay_lengths_by_gender_and_age_answers, # individual and family
        :add_summary_answers, # see SUMMARY_QUESTIONS
        :validate_answers
      ]
      # save our progress
      answer_methods.each_with_index do |method, i|
        percent = ((i/answer_methods.size.to_f)* 100) 
        percent = 0.01 if percent == 0
        Rails.logger.info "Starting #{method}, #{percent.round(2)}% complete"
        report.update(percent_complete: percent)
        GC.start
        
        # Rails.logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
        self.send(method)
        Rails.logger.info "Completed #{method}"
      end
      
      report.update(percent_complete: 100, results: @answers, original_results: @answers, validations: @validations, support: @support, completed_at: Time.now)
      Rails.logger.info "Completed report #{report.report.name}"
      return @answers
    end

    # These are not exhaustive, but provide some simple sanity checks
    def validate_answers
      @answers.each do |sub_type, answers|
        
        undup_count = answers['Undup_Pers_H'].presence
        adults = 0
        children = 0
        if answers['Gnd_A_F'].present?
          adults = answers['Gnd_A_F'] + answers['Gnd_A_M'] + answers['Gnd_A_Mx'] + answers['Gnd_A_Oth'] + answers['Gnd_A_TFM'] + answers['Gnd_A_TMF']
        end
        if answers['Gnd_C_F'].present?
          children = answers['Gnd_C_F'] + answers['Gnd_C_M'] + answers['Gnd_C_Mx'] + answers['Gnd_C_Oth'] + answers['Gnd_C_TFM'] + answers['Gnd_C_TMF']
        end
        # validate sum of hh size should equal unduplicated count
        if answers['HH_Size_1'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Size_1'] + answers['HH_Size_2'] + answers['HH_Size_3'] + answers['HH_Size_4'] + answers['HH_Size_5_GE'] + answers['HH_Size_Mx']
          if current_count != undup_count
            @validations[sub_type]['hh_size'] = "Sum of answers for Household Size HH_Size_* (#{current_count}) should equal the unduplicated client count (#{undup_count})"
          end
        end
        # Validate the sum of household types for individuals is equal to the unduplicated count
        if answers['HH_Typ_C_Only'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Typ_UY'] + answers['HH_Typ_C_Only'] + answers['HH_Typ_A_Only'] + answers['HH_Typ_Ind_A_M'] + answers['HH_Typ_Ind_A_F'] + answers['HH_Typ_Mx']
          if current_count != undup_count
            @validations[sub_type]['hh_type_ind'] = "Sum of answers for Household Type HH_Typ_* (#{current_count}) should equal the unduplicated client count (#{undup_count})"
          end
        end

        # Validate the sum of household types for family is equal to the unduplicated count
        if answers['HH_Typ_A_Fam_C'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Typ_A_Fam_C'] + answers['HH_Typ_C_Fam_A'] + answers['HH_Typ_Mx']
          if current_count != undup_count
            @validations[sub_type]['hh_type_fam'] = "Sum of answers for Household Types for families HH_Typ_*_Fam (#{current_count}) should equal the unduplicated client count (#{undup_count})"
          end
        end

        # Validate household types adults with children should equal the number of adults
        if answers['HH_Typ_A_Fam_C'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Typ_A_Fam_C']
          if current_count != adults
            @validations[sub_type]['hh_type_a_fam_c'] = "The number of Households of type Adults with Children HH_Typ_A_Fam_C (#{current_count}) should equal the adult client count (#{adults})"
          end
        end

        # Validate household types children with adults should equal the number of children
        if answers['HH_Typ_C_Fam_A'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Typ_C_Fam_A']
          if current_count != children
            @validations[sub_type]['hh_type_c_fam_a'] = "The number of Households of type Children with Adults HH_Typ_C_Fam_A (#{current_count}) should equal the children client count (#{children})"
          end
        end

        # validate that household types that only contain adults add up to the adult count
        if answers['HH_Typ_Ind_A_F'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Typ_Ind_A_F'] + answers['HH_Typ_Ind_A_M'] + answers['HH_Typ_A_Only'] + answers['HH_Typ_Mx']
          if current_count != adults
            @validations[sub_type]['hh_type_adults'] = "Sum of answers for Household Types households that should only contain adults HH_Typ_Ind_A_* & HH_Typ_A_only (#{current_count}) should equal the adult client count (#{adults})"
          end
        end
        # validate that household types that only contain children add up to the children count
        if answers['HH_Typ_C_Only'].present?
          @validations[sub_type] ||= {}
          current_count = answers['HH_Typ_C_Only'] + answers['HH_Typ_UY']
          if current_count != children
            @validations[sub_type]['hh_type_children'] = "Sum of answers for Household Types households that should only contain children HH_Typ_C_only & HH_Typ_UY (#{current_count}) should equal the child client count (#{children})"
          end
        end

        # Validate the sum of age questions is equal to the unduplicated count
        if answers['Age_LT_1'].present?
          @validations[sub_type] ||= {}
          current_count = answers['Age_LT_1'] + answers['Age_Mx'] + answers['Age_1_5'] + answers['Age_6_12'] + answers['Age_13_17'] + answers['Age_18_24'] + answers['Age_25_30'] + answers['Age_31_50'] + answers['Age_51_61'] + answers['Age_62_GE']
          if current_count != undup_count
            @validations[sub_type]['age'] = "Sum of answers for Clients by Age Age_* (#{current_count}) should equal the unduplicated client count (#{undup_count})"
          end
        end
        
        # validate the sum of prior living situations for individuals is equal to the unduplicated count
        if answers['Lvn_B4_Prg_Ent_ES'].present? && sub_type.include?('IND')
          @validations[sub_type] ||= {}
          current_count = answers['Lvn_B4_Prg_Ent_ES'] + answers['Lvn_B4_Prg_Ent_Fam'] + answers['Lvn_B4_Prg_Ent_Foster'] + answers['Lvn_B4_Prg_Ent_Fren'] + answers['Lvn_B4_Prg_Ent_Hotel'] + answers['Lvn_B4_Prg_Ent_Hsptl'] + answers['Lvn_B4_Prg_Ent_Jail'] + answers['Lvn_B4_Prg_Ent_Mx'] + answers['Lvn_B4_Prg_Ent_N_4_Hbt'] + answers['Lvn_B4_Prg_Ent_Oth'] + answers['Lvn_B4_Prg_Ent_Own_NS'] + answers['Lvn_B4_Prg_Ent_Own_S'] + answers['Lvn_B4_Prg_Ent_Psych'] + answers['Lvn_B4_Prg_Ent_PSH'] + answers['Lvn_B4_Prg_Ent_Rent_NS'] + answers['Lvn_B4_Prg_Ent_Rent_Oth_S'] + answers['Lvn_B4_Prg_Ent_Rent_VS'] + answers['Lvn_B4_Prg_Ent_SAbse'] + answers['Lvn_B4_Prg_Ent_SH'] + answers['Lvn_B4_Prg_Ent_TH']
          if current_count != undup_count
            @validations[sub_type]['lvn_b4_ind'] = "Sum of answers for Prior Living Situation Lvn_B4_Prg_* (#{current_count}) should equal the unduplicated count (#{undup_count})"
          end
        end

        # validate the sum of prior living situations for families is equal to the adult count
        if answers['Lvn_B4_Prg_Ent_ES'].present? && sub_type.include?('FAM')
          @validations[sub_type] ||= {}
          current_count = answers['Lvn_B4_Prg_Ent_ES'] + answers['Lvn_B4_Prg_Ent_Fam'] + answers['Lvn_B4_Prg_Ent_Foster'] + answers['Lvn_B4_Prg_Ent_Fren'] + answers['Lvn_B4_Prg_Ent_Hotel'] + answers['Lvn_B4_Prg_Ent_Hsptl'] + answers['Lvn_B4_Prg_Ent_Jail'] + answers['Lvn_B4_Prg_Ent_Mx'] + answers['Lvn_B4_Prg_Ent_N_4_Hbt'] + answers['Lvn_B4_Prg_Ent_Oth'] + answers['Lvn_B4_Prg_Ent_Own_NS'] + answers['Lvn_B4_Prg_Ent_Own_S'] + answers['Lvn_B4_Prg_Ent_Psych'] + answers['Lvn_B4_Prg_Ent_PSH'] + answers['Lvn_B4_Prg_Ent_Rent_NS'] + answers['Lvn_B4_Prg_Ent_Rent_Oth_S'] + answers['Lvn_B4_Prg_Ent_Rent_VS'] + answers['Lvn_B4_Prg_Ent_SAbse'] + answers['Lvn_B4_Prg_Ent_SH'] + answers['Lvn_B4_Prg_Ent_TH']
          if current_count != adults
            @validations[sub_type]['lvn_b4_ind'] = "Sum of answers for Prior Living Situation Lvn_B4_Prg_* (#{current_count}) should equal the adult count (#{adults})"
          end
        end

        # validate the sum of prior living lengths for families is equal to the adults count
        if answers['Stb_Prv_Nt_G_Wk_L_Mnt'].present? && sub_type.include?('FAM')
          @validations[sub_type] ||= {}
          current_count = answers['Stb_Prv_Nt_G_Wk_L_Mnt'] + answers['Stb_Prv_Nt_G_3_Mt_L_Yr'] + answers['Stb_Prv_Nt_Mx'] + answers['Stb_Prv_Nt_1_Wk_LE'] + answers['Stb_Prv_Nt_1_Yr_GE'] + answers['Stb_Prv_Nt_1_3_Mnt']
          if current_count != adults
            @validations[sub_type]['lvn_b4'] = "Sum of answers for Prior Living Length Stb_Prv_Nt_* (#{current_count}) should equal the adult count (#{adults})"
          end
        end

        # validate the sum of prior living lengths for individuals is equal to the unduplicated count
        if answers['Stb_Prv_Nt_G_Wk_L_Mnt'].present? && sub_type.include?('IND')
          @validations[sub_type] ||= {}
          current_count = answers['Stb_Prv_Nt_G_Wk_L_Mnt'] + answers['Stb_Prv_Nt_G_3_Mt_L_Yr'] + answers['Stb_Prv_Nt_Mx'] + answers['Stb_Prv_Nt_1_Wk_LE'] + answers['Stb_Prv_Nt_1_Yr_GE'] + answers['Stb_Prv_Nt_1_3_Mnt']
          if current_count != undup_count
            @validations[sub_type]['lvn_b4'] = "Sum of answers for Prior Living Length Stb_Prv_Nt_* (#{current_count}) should equal the unduplicated count (#{undup_count})"
          end
        end

        # validate the sum of disability questions should equal the count of adults
        if answers['Disabled_Mx'].present?
          @validations[sub_type] ||= {}
          current_count = answers['Disabled_Mx'] + answers['Disabled_No'] + answers['Disabled_Yes']
          if current_count != adults
            @validations[sub_type]['disability'] = "Sum of Disability answers Disabled_* (#{current_count}) should equal the sum of adults by gender (#{adults})"
          end
        end

        # validate the sum of veteran questions should equal the count of adults
        if answers['NVet'].present?
          @validations[sub_type] ||= {}
          current_count = answers['NVet'] + answers['Vet'] + answers['Vet_Mx']
          if current_count != adults
            @validations[sub_type]['veteran'] = "Sum of Veteran answers NVet, Vet, VetMx (#{current_count}) should equal the sum of adults by gender (#{adults})"
          end
        end

        # validate the sum of female length of stay questions should equal the count of adults
        if answers['A_F_Nt_Mx'].present?
          @validations[sub_type] ||= {}
          current_count = answers['A_F_Nt_Mx'] + answers['A_F_Nt_1_7'] + answers['A_F_Nt_8_30'] + answers['A_F_Nt_31_60'] + answers['A_F_Nt_61_90'] + answers['A_F_Nt_91_120'] + answers['A_F_Nt_121_150'] + answers['A_F_Nt_151_180'] + answers['A_F_Nt_181_210'] + answers['A_F_Nt_211_240'] + answers['A_F_Nt_241_270'] + answers['A_F_Nt_271_300'] + answers['A_F_Nt_301_330'] + answers['A_F_Nt_331_360'] + answers['A_F_Nt_361_365']
          female_adults = answers['Gnd_A_F'] + answers['Gnd_A_TMF']
          if current_count != female_adults
            @validations[sub_type]['adult_female_length_of_stay'] = "Sum of Adult Female length of stay questions A_F_Nt_* (#{current_count}) should equal the sum of adults who are female + adults who are TMF (#{female_adults})"
          end
        end

        # validate the sum of male length of stay questions should equal the count of adults
        if answers['A_M_Nt_Mx'].present?
          @validations[sub_type] ||= {}
          current_count = answers['A_M_Nt_Mx'] + answers['A_M_Nt_1_7'] + answers['A_M_Nt_8_30'] + answers['A_M_Nt_31_60'] + answers['A_M_Nt_61_90'] + answers['A_M_Nt_91_120'] + answers['A_M_Nt_121_150'] + answers['A_M_Nt_151_180'] + answers['A_M_Nt_181_210'] + answers['A_M_Nt_211_240'] + answers['A_M_Nt_241_270'] + answers['A_M_Nt_271_300'] + answers['A_M_Nt_301_330'] + answers['A_M_Nt_331_360'] + answers['A_M_Nt_361_365']
          male_adults = answers['Gnd_A_M'] + answers['Gnd_A_TFM']
          if current_count != male_adults
            @validations[sub_type]['adult_male_length_of_stay'] = "Sum of Adult Male length of stay questions A_F_Nt_* (#{current_count}) should equal the sum of adults who are male + adults who are TFM (#{male_adults})"
          end
        end

        # validate the sum of child female length of stay questions should equal the count of adults
        if answers['C_F_Nt_Mx'].present?
          @validations[sub_type] ||= {}
          current_count = answers['C_F_Nt_Mx'] + answers['C_F_Nt_1_7'] + answers['C_F_Nt_8_30'] + answers['C_F_Nt_31_60'] + answers['C_F_Nt_61_90'] + answers['C_F_Nt_91_120'] + answers['C_F_Nt_121_150'] + answers['C_F_Nt_151_180'] + answers['C_F_Nt_181_210'] + answers['C_F_Nt_211_240'] + answers['C_F_Nt_241_270'] + answers['C_F_Nt_271_300'] + answers['C_F_Nt_301_330'] + answers['C_F_Nt_331_360'] + answers['C_F_Nt_361_365']
          female_children = answers['Gnd_C_F'] + answers['Gnd_C_TMF']
          if current_count != female_children
            @validations[sub_type]['child_female_length_of_stay'] = "Sum of Child Female length of stay questions C_F_Nt_* (#{current_count}) should equal the sum of children who are female + children who are TMF (#{female_children})"
          end
        end

        # validate the sum of child male length of stay questions should equal the count of adults
        if answers['C_M_Nt_Mx'].present?
          @validations[sub_type] ||= {}
          current_count = answers['C_M_Nt_Mx'] + answers['C_M_Nt_1_7'] + answers['C_M_Nt_8_30'] + answers['C_M_Nt_31_60'] + answers['C_M_Nt_61_90'] + answers['C_M_Nt_91_120'] + answers['C_M_Nt_121_150'] + answers['C_M_Nt_151_180'] + answers['C_M_Nt_181_210'] + answers['C_M_Nt_211_240'] + answers['C_M_Nt_241_270'] + answers['C_M_Nt_271_300'] + answers['C_M_Nt_301_330'] + answers['C_M_Nt_331_360'] + answers['C_M_Nt_361_365']
          male_children = answers['Gnd_C_M'] + answers['Gnd_C_TFM']
          if current_count != male_children
            @validations[sub_type]['child_male_length_of_stay'] = "Sum of Adult Male length of stay questions A_F_Nt_* (#{current_count}) should equal the sum of children who are male + children who are TFM (#{male_children})"
          end
        end

        # Validate counts of exits
        if answers['Pers_Exited_PSH'].present?
          @validations[sub_type] ||= {}
          current_count = answers['Pers_Dest_Exit_D'] + answers['Pers_Dest_Exit_ES'] + answers['Pers_Dest_Exit_Fam_Perm'] + answers['Pers_Dest_Exit_Fam_Temp'] + answers['Pers_Dest_Exit_Foster'] + answers['Pers_Dest_Exit_Fren_Temp'] + answers['Pers_Dest_Exit_Fren_Perm'] + answers['Pers_Dest_Exit_Hotel'] + answers['Pers_Dest_Exit_Hsptl'] + answers['Pers_Dest_Exit_Jail'] + answers['Pers_Dest_Exit_Mx'] + answers['Pers_Dest_Exit_N_4_Hbt'] + answers['Pers_Dest_Exit_Oth'] + answers['Pers_Dest_Exit_Own_NS'] + answers['Pers_Dest_Exit_Own_WS'] + answers['Pers_Dest_Exit_Psych'] + answers['Pers_Dest_Exit_PSH'] + answers['Pers_Dest_Exit_Rent_NS'] + answers['Pers_Dest_Exit_Rent_Oth_S'] + answers['Pers_Dest_Exit_Rent_VS'] + answers['Pers_Dest_Exit_SAbse'] + answers['Pers_Dest_Exit_SH'] + answers['Pers_Dest_Exit_TH']
          if current_count != answers['Pers_Exited_PSH']
            @validations[sub_type]['psh_exits'] = "Sum of people who exited by destination Pers_Dest_Exit_* (#{current_count}) should equal the number of people who exited Pers_Exited_PSH (#{answers['Pers_Exited_PSH']})"
          end
        end
      end
    end

    def add_summary_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        sheltered_in = entries.map do |e|
          project_type = e[service_history_project_type_index]
          family = entry_belongs_to_family(e)
          sub_type(project_type, family)
        end.uniq.compact - ['PSH-FAM', 'PSH-IND']
        case sheltered_in.sort
          # 4
        when ["ES-FAM", "ES-IND", "TH-FAM", "TH-IND"]
          @answers['Summary']['Pers_all_4_Prog'] += 1
          # 3
        when ["ES-FAM", "ES-IND", "TH-FAM"]
          @answers['Summary']['Pers_only_EI_EF_TF'] += 1
        when ["ES-FAM", "ES-IND", "TH-IND"]
          @answers['Summary']['Pers_only_EI_EF_TI'] += 1
        when ["ES-FAM", "TH-FAM", "TH-IND"]
          @answers['Summary']['Pers_only_EF_TI_TF'] += 1
        when ["ES-IND", "TH-FAM", "TH-IND"]
          @answers['Summary']['Pers_only_EI_TI_TF'] += 1
          # 2
        when ["ES-FAM", "ES-IND"]
          @answers['Summary']['Pers_only_EI_EF'] += 1
        when ["ES-FAM", "TH-IND"]
          @answers['Summary']['Pers_only_EF_TI'] += 1
        when ["ES-IND", "TH-IND"]
          @answers['Summary']['Pers_only_EI_TI'] += 1
        when ["ES-FAM", "TH-FAM"]
          @answers['Summary']['Pers_only_EF_TF'] += 1
        when ["ES-IND", "TH-FAM"]
          @answers['Summary']['Pers_only_EI_TF'] += 1
        when ["TH-FAM", "TH-IND"]
          @answers['Summary']['Pers_only_TI_TF'] += 1
          # 1
        when ["ES-FAM"]
          @answers['Summary']['Pers_only_EF'] += 1
        when ["ES-IND"]
          @answers['Summary']['Pers_only_EI'] += 1 
        when ["TH-IND"]
          @answers['Summary']['Pers_only_TI'] += 1
        when ["TH-FAM"]
          @answers['Summary']['Pers_only_TF'] += 1        
        end
      end
    end

    def add_psh_most_recent_stay_lengths_by_gender_and_age_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        gender = gender_code(client_metadata_by_client_id[id][client_gender_index], false).gsub('Mx_Gnd', 'MX')
        
        psh_ind_stays = entries.select do |e|
          psh = PH.include?(e[service_history_project_type_index])
          family = entry_belongs_to_family(e)
          # Pick any PSH stays where the client was not in a family 
          psh && ! family
        end
        most_recent_psh_ind_stay = psh_ind_stays.last
        
        psh_fam_stays = entries.select do |e|
          psh = PH.include?(e[service_history_project_type_index])
          family = entry_belongs_to_family(e)
          # Pick any PSH stays where the client was in a family 
          psh && family
        end
        most_recent_psh_fam_stay = psh_fam_stays.last
        
        # PSH IND
        if most_recent_psh_ind_stay.present? && most_recent_psh_ind_stay.any?
          psh_ind_life_stage = stage_in_life(id, psh_ind_stays.first)
          exit_date = most_recent_psh_ind_stay[service_history_last_date_in_program_index] || @report_end
          if exit_date.to_date > @report_end.to_date
            exit_date = @report_end
          end
          entry_date = most_recent_psh_ind_stay[service_history_first_date_in_program_index]
          stay_length = psh_length_of_stay_category((exit_date.to_date - entry_date.to_date).to_i)
          @answers['PSH-IND']["Pers_Rct_#{psh_ind_life_stage}_#{gender}_Nts_#{stay_length.upcase}"] += 1
        end
        #PSH FAM
        if most_recent_psh_fam_stay.present? && most_recent_psh_fam_stay.any?
          psh_fam_life_stage = stage_in_life(id, psh_fam_stays.first)
          exit_date = most_recent_psh_fam_stay[service_history_last_date_in_program_index] || @report_end
          if exit_date.to_date > @report_end.to_date
            exit_date = @report_end
          end
          entry_date = most_recent_psh_fam_stay[service_history_first_date_in_program_index]
          stay_length = psh_length_of_stay_category((exit_date.to_date - entry_date.to_date).to_i)
          @answers['PSH-FAM']["Pers_Rct_#{psh_fam_life_stage}_#{gender}_Nts_#{stay_length.upcase}"] += 1
        end
      end
    end

    def add_psh_also_other_project_type_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        sheltered_in = entries.map do |e|
          project_type = e[service_history_project_type_index]
          family = entry_belongs_to_family(e)
          sub_type(project_type, family).gsub('-', '_')
        end.uniq.compact
        if sheltered_in.include?('PSH_IND')
          (sheltered_in - ['PSH_IND']).each do |m|
            slug = "Pers_PSH_also_#{m}"
            if m == 'PSH_FAM'
              slug = 'Pers_PSH_IND_also_PSH_FAM'
            end
            @answers['PSH-IND'][slug] += 1
          end
        end
        if sheltered_in.include?('PSH_FAM')
          (sheltered_in - ['PSH_FAM']).each do |m|
            slug = "Pers_PSH_also_#{m}"
            if m == 'PSH_IND'
              slug = 'Pers_PSH_FAM_also_PSH_IND'
            end
            @answers['PSH-FAM'][slug] += 1
          end
        end
      end 
    end

    def add_psh_entry_exit_answers
      counted_clients = Set.new
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        entries.each do |e|
          if PH.include?(e[service_history_project_type_index])
            project_type = e[service_history_project_type_index]
            family = entry_belongs_to_family(e)
            sub_type = sub_type(project_type, family)
            exit_date = e[service_history_last_date_in_program_index]
            destination = destination_code(e[service_history_destination_index])
            if ! counted_clients.include?([id, sub_type, 'entry'])
              @answers[sub_type]['Pers_Entered_PSH'] += 1
              counted_clients << [id, sub_type, 'entry']
            end
            if exit_date.present?
              if ! counted_clients.include?([id, sub_type, 'exit'])
                if exit_date.to_date <= @report_end.to_date && exit_date.to_date >= @report_start.to_date
                  @answers[sub_type]['Pers_Exited_PSH'] += 1
                  @answers[sub_type]["Pers_Dest_Exit_#{destination}"] += 1
                  counted_clients << [id, sub_type, 'exit']
                end
              end
            end
          end
        end
      end
    end

    def add_psh_disabilities
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        psh = false
        entries.each do |e|
          break if psh
          if PH.include?(e[service_history_project_type_index])
            psh = true
            project_type = e[service_history_project_type_index]
            family = entry_belongs_to_family(e)
            if disabilities_by_client_id[id].present?
              disabilities = disabilities_by_client_id[id].map do |d|
                disability_type_slug(d)
              end.compact.uniq
              if disabilities.include?('Ment_Health') && disabilities.include?('Sub_Abuse')
                disabilities << 'Ment_Health_and_Sub_Abuse'
                disabilities.delete('Ment_Health')
                disabilities.delete('Sub_Abuse')
              end
              disabilities.each do |d|
                @answers[sub_type(project_type, family)]["Pers_Disability_#{d}"] += 1
              end
            end
          end
        end
      end
    end

    # Find distinct (PSH, destination) enrollments for each client 
    # def add_psh_destination_answers
    #   entries_by_client_id.each do |id, entries|
    #     destinations = entries.map do |e|
    #       if e[service_history_destination_index].present? && PH.include?(e[service_history_project_type_index]) && e[service_history_last_date_in_program_index].to_date <= @report_end.to_date
    #           project_type = e[service_history_project_type_index]
    #           family = entry_belongs_to_family(e)
    #           dest = destination_code(e[service_history_destination_index])
    #           [project_type, family, dest]
    #       end
    #     end.compact.uniq
    #     destinations.each do |project_type, family, destination|
    #       @answers[sub_type(project_type, family)]["Pers_Dest_Exit_#{destination}"] += 1
    #     end
    #   end
    # end

    # loop over all entries for each client, count each client once per project type
    # where the household type is determined like so:
    # Ind_A_F - client was the only person in the household and an adult female
    # Ind_A_M - client was the only person in the household and an adult male
    # HH_Typ_UY - Unacommpanied child, presenting as an individual
    # HH_Typ_C_Only - Children only, any number
    # HH_Typ_A_Only - Adults only, more than one
    # 
    # ... (See documentation)
    #
    # Child < 18
    # Adult >= 18
    def add_individual_household_type_answers
      # only count each client once per project_type
      counted_clients = Set.new
      entries_by_client_id.each do |client_id, entries|
        next unless vet_check(client_id: client_id)
        gender = gender_code(client_metadata_by_client_id[client_id][client_gender_index], false)
        
        entries.each do |entry|
          # We only care about non-families
          household_id = entry[service_history_household_id_index]
          project_type = entry[service_history_project_type_index]
          data_source_id = entry[service_history_data_source_id_index]
          project_id = entry[service_history_project_id_index]
          size = households[[household_id, data_source_id, project_id]].try(:[], :size) || 1
          # many individuals don't get a household id, otherwise, we'll check that
          # the specific household id isn't a family id
          if household_id.blank? || ! households[[household_id, data_source_id, project_id]].try(:[], :family)
            if TH.include?(project_type)
              the_sub_type = 'TH-IND'
            elsif ES.include?(project_type)
              the_sub_type = 'ES-IND'
            elsif PH.include?(project_type)
              the_sub_type = 'PSH-IND'
            end
            unless counted_clients.include?([client_id, the_sub_type])
              adult = false
              child = false
              first_entry = first_entry_in_category(client_id, the_sub_type)
              age = first_entry[service_history_age_index] || infer_adulthood(client_id)
              if age.present? && age < ADULT
                child = true
              else
                adult = true
              end
              if size == 1 && child
                household_type_slug = 'HH_Typ_UY' # Unaccompanied Youth
              elsif child
                household_type_slug = 'HH_Typ_C_Only' # Children Only
              else
                if size == 1 && (gender == 'F' || gender == 'M')
                  household_type_slug = "HH_Typ_Ind_A_#{gender}" # individual adults by gender
                elsif size > 1
                  household_type_slug = 'HH_Typ_A_Only' # Adults only, more than one together
                else
                  household_type_slug = 'HH_Typ_Mx'
                end
              end
              
              @answers[the_sub_type][household_type_slug] += 1
              counted_clients << [client_id, the_sub_type]
            end
          end
        end
      end
    end

    def add_household_date_answers
      CENSUS_DATES.each do |slug, d|
        # Get all service_history records for this date (record_type: 'service')
        services = involved_entries_scope
          .where(date: d, record_type: 'service').select(act_as_project_overlay, :household_id, :data_source_id, :project_id).distinct.pluck(act_as_project_overlay, :household_id, :data_source_id, :project_id)
        .map do |project_type, household_id, data_source_id, project_id|
          # only care about families
          if households[[household_id, data_source_id, project_id]].present? && households[[household_id, data_source_id, project_id]][:family]
            if TH.include?(project_type)
              group = 'TH-FAM'
            elsif ES.include?(project_type)
              group = 'ES-FAM'
            elsif PH.include?(project_type)
              group = 'PSH-FAM'
            end
            [group, household_id]
          end
        end.uniq.compact
        services.uniq.each do |group, household_id|
          @answers[group]["HHs_#{slug}"] += 1
        end
      end
    end

    def add_family_answers
      th_households = []
      es_households = []
      psh_households = []
      counted_households = Set.new
      headers = ['Client ID', 'Project Name', 'ProjectID', 'Data Source']
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        # Find the entries into TH-FAM, ES-FAM and PSH-FAM
        # 1. Entry must be in appropriate project type
        # 2. Household size at entry must be greater than 1
        fam_th_entries = entries.select do |entry|
          TH.include?(entry[service_history_project_type_index]) && entry_belongs_to_family(entry)
        end
        fam_es_entries = entries.select do |entry|
          ES.include?(entry[service_history_project_type_index]) && entry_belongs_to_family(entry)
        end
        fam_ph_entries = entries.select do |entry|
          PH.include?(entry[service_history_project_type_index]) && entry_belongs_to_family(entry)
        end
        if fam_th_entries.any?
          household_types = []
          @support['TH-FAM']['HH_Typ_C_Fam_A'] ||= {}
          @support['TH-FAM']['HH_Typ_C_Fam_A'][:headers] ||= headers
          @support['TH-FAM']['HH_Typ_C_Fam_A'][:counts] ||= []
          @support['TH-FAM']['HH_Typ_A_Fam_C'] ||= {}
          @support['TH-FAM']['HH_Typ_A_Fam_C'][:headers] ||= headers
          @support['TH-FAM']['HH_Typ_A_Fam_C'][:counts] ||= []
          fam_th_entries.each do |entry|
            household_id = entry[service_history_household_id_index]
            data_source_id = entry[service_history_data_source_id_index]
            client_id = entry[service_history_client_id_index]
            age = entry[service_history_age_index] || infer_adulthood(client_id)
            # Only count each individual once
            if ! counted_households.include?([client_id, 'TH-FAM'])
              project_name = entry[service_history_project_name_index]
              project_id = entry[service_history_project_id_index]
              if age.present? && age < ADULT
                @answers['TH-FAM']['HH_Typ_C_Fam_A'] += 1
                @support['TH-FAM']['HH_Typ_C_Fam_A'][:counts] << [id, project_name, project_id, data_source_id]
              else
                @answers['TH-FAM']['HH_Typ_A_Fam_C'] += 1
                @support['TH-FAM']['HH_Typ_A_Fam_C'][:counts] << [id, project_name, project_id, data_source_id]
              end
              counted_households << [client_id, 'TH-FAM']
            end
            th_households << household_id
          end
        end
        if fam_es_entries.any?
          household_types = []
          @support['ES-FAM']['HH_Typ_C_Fam_A'] ||= {}
          @support['ES-FAM']['HH_Typ_C_Fam_A'][:headers] ||= headers
          @support['ES-FAM']['HH_Typ_C_Fam_A'][:counts] ||= []
          @support['ES-FAM']['HH_Typ_A_Fam_C'] ||= {}
          @support['ES-FAM']['HH_Typ_A_Fam_C'][:headers] ||= headers
          @support['ES-FAM']['HH_Typ_A_Fam_C'][:counts] ||= []
          fam_es_entries.each do |entry|
            household_id = entry[service_history_household_id_index]
            data_source_id = entry[service_history_data_source_id_index]
            client_id = entry[service_history_client_id_index]
            age = entry[service_history_age_index] || infer_adulthood(client_id)
            # Only count each individual once
            if ! counted_households.include?([client_id, 'ES-FAM'])
              project_name = entry[service_history_project_name_index]
              project_id = entry[service_history_project_id_index]
              if age.present? && age < ADULT
                @answers['ES-FAM']['HH_Typ_C_Fam_A'] += 1
                @support['ES-FAM']['HH_Typ_C_Fam_A'][:counts] << [id, project_name, project_id, data_source_id]
              else
                @answers['ES-FAM']['HH_Typ_A_Fam_C'] += 1
                @support['ES-FAM']['HH_Typ_A_Fam_C'][:counts] << [id, project_name, project_id, data_source_id]
              end
              counted_households << [client_id, 'ES-FAM']
            end
            es_households << household_id
          end
        end
        if fam_ph_entries.any?
          household_types = []
          @support['PSH-FAM']['HH_Typ_C_Fam_A'] ||= {}
          @support['PSH-FAM']['HH_Typ_C_Fam_A'][:headers] ||= headers
          @support['PSH-FAM']['HH_Typ_C_Fam_A'][:counts] ||= []
          @support['PSH-FAM']['HH_Typ_A_Fam_C'] ||= {}
          @support['PSH-FAM']['HH_Typ_A_Fam_C'][:headers] ||= headers
          @support['PSH-FAM']['HH_Typ_A_Fam_C'][:counts] ||= []
          fam_ph_entries.each do |entry|
            household_id = entry[service_history_household_id_index]
            data_source_id = entry[service_history_data_source_id_index]
            client_id = entry[service_history_client_id_index]
            age = entry[service_history_age_index] || infer_adulthood(client_id)
            # Only count each individual once
            if ! counted_households.include?([client_id, 'PSH-FAM'])
              project_name = entry[service_history_project_name_index]
              project_id = entry[service_history_project_id_index]
              if age.present? && age < ADULT
                @answers['PSH-FAM']['HH_Typ_C_Fam_A'] += 1
                @support['PSH-FAM']['HH_Typ_C_Fam_A'][:counts] << [id, project_name, project_id, data_source_id]
              else
                @answers['PSH-FAM']['HH_Typ_A_Fam_C'] += 1
                @support['PSH-FAM']['HH_Typ_A_Fam_C'][:counts] << [id, project_name, project_id, data_source_id]
              end
              counted_households << [client_id, 'PSH-FAM']
            end
            psh_households << household_id
          end
        end
      end
      @answers['TH-FAM']["HHs"] = th_households.uniq.size
      @answers['ES-FAM']["HHs"] = es_households.uniq.size
      @answers['PSH-FAM']["HHs"] = psh_households.uniq.size
    end

    def add_lts_answers
      length_of_stay_per_id_by_project_type.each do |id, stay_lengths|
        next unless vet_check(client_id: id)
        age = entries_by_client_id[id].first[service_history_age_index] || infer_adulthood(id)
        if stay_lengths['ES-FAM'].size > 180
          @answers['ES-FAM']["Lts_#{lts_age_range(age)}"] += 1
          @answers['ES-FAM']["Lts_#{lts_disability(id)}"] += 1
          @answers['ES-FAM']["Lts_#{ethnicity_slug(client_metadata_by_client_id[id][client_ethnicity_index])}"] += 1
          # NOTE: Using household size from first ES entry because the instructions are unlclear
          first_es_entry = entries_by_client_id[id].select do |entry|
            ES.include?(entry[service_history_project_type_index])
          end.first
          household_id = first_es_entry[service_history_household_id_index]
          data_source_id = first_es_entry[service_history_data_source_id_index]
          project_id = first_es_entry[service_history_project_id_index]
          if households[[household_id, data_source_id, project_id]].try(:[], :family)
            @answers['ES-FAM']["Lts_#{household_size_slug(households[[household_id, data_source_id, project_id]][:size])}"] += 1
            # the spec isn't quite consistent on the naming of Vet fields
            veteran = veteran_slug(client_metadata_by_client_id[id][client_veteran_status_index]).gsub('NVet', 'Nvet')
            @answers['ES-FAM']["Lts_#{veteran}"] += 1
            @answers['ES-FAM']["Lts_Race_#{race_slug(client_metadata_by_client_id[id])}"] += 1
          end
        end
        if stay_lengths['ES-IND'].size > 180
          @answers['ES-IND']["Lts_#{lts_age_range(age)}"] += 1
          @answers['ES-IND']["Lts_#{lts_disability(id)}"] += 1
          @answers['ES-IND']["Lts_#{ethnicity_slug(client_metadata_by_client_id[id][client_ethnicity_index])}"] += 1
          # NOTE: Using household size from first ES entry because the instructions are unlclear
          first_es_entry = entries_by_client_id[id].select do |entry|
            ES.include?(entry[service_history_project_type_index])
          end.first
          household_id = first_es_entry[service_history_household_id_index]
          data_source_id = first_es_entry[service_history_data_source_id_index]
          project_id = first_es_entry[service_history_project_id_index]
          size = households[[household_id, data_source_id, project_id]].try(:[], :size) || 1
          @answers['ES-IND']["Lts_#{household_size_slug(size)}"] += 1
          # the spec isn't quite consistent on the naming of Vet fields
          veteran = veteran_slug(client_metadata_by_client_id[id][client_veteran_status_index]).gsub('NVet', 'Nvet')
          @answers['ES-IND']["Lts_#{veteran}"] += 1
          @answers['ES-IND']["Lts_Race_#{race_slug(client_metadata_by_client_id[id])}"] += 1
        end
      end
    end

    def add_unduplicated_count_answers
      clients_by_sub_type.each do |sub_type, clients|
        clients = (all_vets.uniq & clients.to_a) if vets_only
        @answers[sub_type]['Undup_Pers_H'] = clients.size
        @support[sub_type]['Undup_Pers_H'] = {headers: ['Client ID'], counts: clients.map{|m| [m]}}
      end
    end

    # Only count all clients
    def add_prior_living_length_answers
      counted_clients_per_sub_type = Set.new
      entries_by_client_id.each do |client_id, entries|
        next unless vet_check(client_id: client_id)
        unknown_lengths = Set.new
        entries.each do |entry|   
          family = entry_belongs_to_family(entry)
          the_sub_type = sub_type(entry[service_history_project_type_index], family)
          # make sure the client has a record in this sub-type so we don't include them
          # in the Mx counts accidentally
          if client_has_entry_in_sub_type(client_id, the_sub_type) && ! counted_clients_per_sub_type.include?([the_sub_type, client_id])
            first_entry = first_entry_in_category(client_id, the_sub_type)
            age = first_entry[service_history_age_index] || infer_adulthood(client_id)
            # only count adults for families, count everyone for individuals
            if (family && (age.blank? || age >= ADULT)) || ! family
              entry_id = entry[service_history_enrollment_group_id_index]
              data_source_id = entry[service_history_data_source_id_index]
              if involved_enrollments_by_entry_id_and_data_source_id[[entry_id, data_source_id]].present?
                length_code = involved_enrollments_by_entry_id_and_data_source_id[[entry[service_history_enrollment_group_id_index], entry[service_history_data_source_id_index]]][enrollment_prior_residence_length_of_stay_index]
                @answers[the_sub_type]["Stb_Prv_Nt_#{prior_living_length_slug(length_code)}"] += 1
                counted_clients_per_sub_type << [the_sub_type, client_id]
              else
                # Keep track of anyone we don't know lenght for and if we still don't konw at the end, put them into the Stb_Prv_Nt_Mx category
                unknown_lengths << the_sub_type
              end
            end
          end
        end
        # Add Stb_Prv_Nt_Mx category if we still don't have us in a particular category
        unknown_lengths.each do |the_sub_type|
          if client_has_entry_in_sub_type(client_id, the_sub_type) && ! counted_clients_per_sub_type.include?([the_sub_type, client_id])
            @answers[the_sub_type]["Stb_Prv_Nt_Mx"] += 1
          end
        end
      end
    end

    def add_race_answers
      counted_clients_per_sub_type = Set.new
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        client = client_metadata_by_client_id[id]
        entries.each do |entry|
          family = entry_belongs_to_family(entry)
          the_sub_type = sub_type(entry[service_history_project_type_index], family)
          if ! counted_clients_per_sub_type.include?([the_sub_type, id])
            @answers[the_sub_type]["Race_#{race_slug(client)}"] += 1
            counted_clients_per_sub_type << [the_sub_type, id]
          end
        end
      end
    end

    # For ES-FAM 1d: Number of persons in families who used more than one HMIS participating emergency shelter as part of a family.
    # For ES-IND 1d: Number of individuals who used more than one HMIS participating emergency shelter as an individual.
    # For TH-FAM 1d: Number of persons in families who used more than one HMIS participating transitional housing program in a family.
    # For TH-IND 1d: Number of individuals who used more than one HMIS participating transitional housing provider as an individual.
    # For PSH-FAM 1d: Number of Persons in Families who used more than one HMIS-participating PSH program as part of a family.
    # For PSH-IND 1d: Number of individuals who used more than one HMIS-participating PSH program as an individual.
    def add_multi_use_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        client_entries = entries.map do |entry|
          project_type = entry[service_history_project_type_index]
          family = entry_belongs_to_family(entry)
          [sub_type(project_type, family), entry[service_history_project_id_index]]
        end.group_by(&:first)
        client_entries.each do |slug, entries|
          if entries.uniq.size > 1
            @answers[slug]['Pers_Multi_H'] += 1
          end
        end
      end
    end

    def add_average_night_answers
      fam_ids_by_ds = households.select{|k,m| m[:family]}.keys.
        group_by do |household_id, data_source_id, project_id|
          data_source_id
        end
      fam_wheres = []
      fam_ids_by_ds.each do |ds_id, values|
        # values consists of 
        # [household_id, data_source_id]
        fam_wheres << "([warehouse_client_service_history].data_source_id = #{ds_id} and household_id in ('#{values.map(&:first).join("','")}'))"
      end
      fam_where = fam_wheres.join(' or ')

      groups = {
        'PSH' => PH,
        'ES' => ES,
        'TH' => TH,
      }
      counts = {
        'PSH-IND': 0,
        'PSH-FAM': 0,
        'ES-IND': 0,
        'ES-FAM': 0,
        'TH-IND': 0,
        'TH-FAM': 0,
      }
      project_counts = {}
      groups.each do |slug, project_type|
        family_served = if fam_ids_by_ds.any?
          family_scope = involved_entries_scope
            .where(['(Project.act_as_project_type is null and project_type in (?)) or Project.act_as_project_type in (?)', project_type, project_type])
            .where(record_type: 'service')
            .where("[date] >= ?", @report_start)
            .where("[date] <= ?", @report_end)
            .where(fam_where)
            # Save off some supporing info
            family_scope.pluck(*sh_cols).each do |sh|
              project_name = sh[service_history_project_name_index]
              project_id = sh[service_history_project_id_index]
              ds_id = sh[service_history_data_source_id_index]
              row = ["#{slug}-FAM", project_name, project_id, ds_id]
              project_counts[row] ||= Set.new
              project_counts[row] << sh[service_history_client_id_index]
            end
            if vets_only
              family_scope = family_scope.where(client_id: all_vets)
            end
            family_scope.count
          else
            0
          end
        individuals_served = involved_entries_scope
          .where(['(Project.act_as_project_type is null and project_type in (?)) or Project.act_as_project_type in (?)', project_type, project_type])
          .where( record_type: 'service')
          .where("[date] >= ?", @report_start)
          .where("[date] <= ?", @report_end)
        if fam_ids_by_ds.any? 
          individuals_served = individuals_served.where.not(fam_where)
        end
        if vets_only
          individuals_served = individuals_served.where(client_id: all_vets)
        end
        # Save off some supporing info
        individuals_served.pluck(*sh_cols).each do |sh|
          project_name = sh[service_history_project_name_index]
          project_id = sh[service_history_project_id_index]
          ds_id = sh[service_history_data_source_id_index]
          row = ["#{slug}-IND", project_name, project_id, ds_id]
          project_counts[row] ||= Set.new
          project_counts[row] << sh[service_history_client_id_index]
        end
        individuals_served = individuals_served.count
        @answers["#{slug}-FAM"]['Pers_Avg_Ngt'] = (family_served / 365.0).round(2)
        @answers["#{slug}-IND"]['Pers_Avg_Ngt'] = (individuals_served / 365.0).round(2)
      end
      project_counts.each do |k,clients|
        category, project_name, project_id, ds_id = k
        row = [category, project_name, clients.size, project_id, ds_id]
        @support[category]['Pers_Avg_Ngt'] ||= {}
        @support[category]['Pers_Avg_Ngt'][:headers] ||= ['Category', 'Project Name', 'Client Count', 'ProjectID', 'Data Source']
        @support[category]['Pers_Avg_Ngt'][:counts] ||= []
        @support[category]['Pers_Avg_Ngt'][:counts] << row
      end
    end

    def add_specific_date_answers
      CENSUS_DATES.each do |slug, d|
        # Get all service_history records for this date (record_type: 'service')
        # build a unique array of project type, family and client id
        services = involved_entries_scope
          .where(date: d, record_type: 'service')
          .pluck(*sh_cols) # Use the overlayed act_as_project_type
          .map do |m|
            family = entry_belongs_to_family(m)
            project_type = m[service_history_project_type_index]
            [sub_type(project_type, family), m[service_history_client_id_index]]
        end.uniq
        # Useful debugging to get a list of project names for each date
        project_counts = {}
        projects = involved_entries_scope
          .where(date: d, record_type: 'service')
          .pluck(*sh_cols) # Use the overlayed act_as_project_type
          .map do |m|
            family = entry_belongs_to_family(m)
            project_type = m[service_history_project_type_index]
            row = [sub_type(project_type, family), m[service_history_project_id_index], m[service_history_data_source_id_index]]
            project_counts[row] ||= Set.new
            project_counts[row] << m[service_history_client_id_index]
            row
        end.uniq.map do |sub_type, project_id, ds_id| 
          project_name = GrdaWarehouse::Hud::Project
            .where(data_source_id: ds_id, ProjectID: project_id)
            .first.ProjectName
          ds = GrdaWarehouse::DataSource.find(ds_id).short_name
          [sub_type, project_name, project_counts[[sub_type, project_id, ds_id]].size, project_id, ds]
        end.group_by(&:first) # sub_type
        projects.each do |sub_type, project_list|
          @support[sub_type]["Pers_#{slug}"] = {
            headers: ['Category', 'Project Name', 'Client Count', 'ProjectID', 'Data Source'],
            counts: project_list,
          }
        end
        # puts "DATE: #{slug} #{d}"
        # puts projects.inspect
        services.each do |sub_type, client_id|
          next unless vet_check(client_id: client_id)
          @answers[sub_type]["Pers_#{slug}"] += 1
        end
      end
    end

    # Only count adults
    def add_veteran_answers
      counted_clients_per_sub_type = Set.new
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        client = client_metadata_by_client_id[id]
        veteran = veteran_slug(client[client_veteran_status_index])
        
        distinct_sub_types = entries.map do |entry|
          project_type = entry[service_history_project_type_index]
          family = entry_belongs_to_family(entry)
          sub_type(project_type, family)
        end.uniq.compact
        distinct_sub_types.each do |sub_type|
          first_entry = first_entry_in_category(id, sub_type)
          age = first_entry[service_history_age_index] || infer_adulthood(id)
          # only count adults
          if age.blank? || age >= ADULT
            @answers[sub_type][veteran] += 1
            @support[sub_type][veteran] ||= {}
            @support[sub_type][veteran][:headers] ||= ['Client ID']
            @support[sub_type][veteran][:counts] ||= []
            @support[sub_type][veteran][:counts] << [id]
          end
        end
      end
    end

    # Per the error reports:
    # The sum of all prior living situations (Lvn_B4_Prg_Ent_*) 
    # should equal the sum of all unduplicated clients
    # This implies that we only:
    #   1. count all clients
    #   2. count only the first entry for each client per sub type (ES-IND, ES-FAM)
    def add_prior_living_situation_answers
      counted_clients_per_sub_type = Set.new
      unknown_clients = Set.new
      entries_by_client_id.each do |client_id, entries|
        next unless vet_check(client_id: client_id)
        entries.each do |entry|
          project_type = entry[service_history_project_type_index]
          family = entry_belongs_to_family(entry)
          the_sub_type = sub_type(project_type, family)
          # make sure the client has a record in this sub-type so we don't include them
          # in the Mx counts accidentally
          if client_has_entry_in_sub_type(client_id, the_sub_type)
            # only count adults for families, count everyone for individuals
            first_entry = first_entry_in_category(client_id, the_sub_type)
            age = first_entry[service_history_age_index] || infer_adulthood(client_id)
            if (family && (age.blank? || age >= ADULT)) || ! family
              entry_id = entry[service_history_enrollment_group_id_index]
              data_source_id = entry[service_history_data_source_id_index]
              prior_living_situation = involved_enrollments_by_entry_id_and_data_source_id[[entry_id, data_source_id]].try(:[], enrollment_prior_residence_index)
              unless counted_clients_per_sub_type.include?([the_sub_type, client_id])
                @answers[the_sub_type][prior_living_situation_slug(prior_living_situation)] += 1
                counted_clients_per_sub_type << [the_sub_type, client_id]
              end
            end
          end
        end
      end
    end

    def add_household_answers
      counted_clients_per_sub_type = Set.new
      entries_by_client_id.each do |client_id, entries|
        next unless vet_check(client_id: client_id)
        distinct_project_types_with_household_ids = entries.map do |m|
          project_type = m[service_history_project_type_index]
          household_id = m[service_history_household_id_index]
          data_source_id = m[service_history_data_source_id_index]
          project_id = m[service_history_project_id_index]
          [project_type, household_id, data_source_id, project_id]
        end.uniq
        distinct_project_types_with_household_ids.each do |project_type, household_id, data_source_id, project_id|
          size = households[[household_id, data_source_id, project_id]].try(:[], :size) || 1
          family = households[[household_id, data_source_id, project_id]].try(:[], :family) || false
          the_sub_type = sub_type(project_type, family)
          unless counted_clients_per_sub_type.include?([client_id, the_sub_type])
            @answers[the_sub_type][household_size_slug(size)] += 1
            counted_clients_per_sub_type << [client_id, the_sub_type]
            @support[the_sub_type][household_size_slug(size)] ||= {}
            @support[the_sub_type][household_size_slug(size)][:headers] ||= ['Client ID', 'Household ID', 'Data Source ID', 'Project ID']
            @support[the_sub_type][household_size_slug(size)][:counts] ||= []
            @support[the_sub_type][household_size_slug(size)][:counts] << [client_id, household_id, data_source_id, project_id]
          end
        end
      end
    end

    def add_gender_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)      
        distinct_project_types = entries.map do |m|
          project_type = m[service_history_project_type_index]
          family = entry_belongs_to_family(m)
          sub_type(project_type, family)
        end.uniq.compact
        distinct_project_types.each do |sub_type|
          first_entry = first_entry_in_category(id, sub_type)
          gender = gender_slug(id, first_entry)
          @answers[sub_type][gender] += 1
          @support[sub_type][gender] ||= {}
          @support[sub_type][gender][:headers] ||= ['Client ID']
          @support[sub_type][gender][:counts] ||= []
          @support[sub_type][gender][:counts] << [id]
        end
      end
    end

    def add_ethnicity_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        first_entry = entries.first
        ethnicity = ethnicity_slug(client_metadata_by_client_id[id][client_ethnicity_index])
        distinct_project_types = entries.map do |m|
          project_type = m[service_history_project_type_index]
          family = entry_belongs_to_family(m)
          sub_type(project_type, family)
        end.uniq.compact
        distinct_project_types.each do |sub_type|
          @answers[sub_type][ethnicity] += 1
        end
      end
    end

    # find if any adults, 18+ based on their first entry, and get distinct sub-type have Disabling Conditions in their first entry
    def add_disability_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)
        disability = disability_slug(entries) 
        distinct_project_types = entries.map do |m|
          project_type = m[service_history_project_type_index]
          family = entry_belongs_to_family(m)
          sub_type(project_type, family)
        end.uniq.compact
        distinct_project_types.each do |sub_type|
          first_entry = first_entry_in_category(id, sub_type)
          age = first_entry[service_history_age_index] || infer_adulthood(id)
          if age.blank? || age >= ADULT
            @answers[sub_type][disability] += 1
          end
        end
      end
    end

    # of people served at HMIS participating providers where broken down by age
    def add_age_answers
      entries_by_client_id.each do |id, entries|
        next unless vet_check(client_id: id)    
        distinct_project_types = entries.map do |m|
          project_type = m[service_history_project_type_index]
          family = entry_belongs_to_family(m)
          sub_type(project_type, family)
        end.uniq.compact
        distinct_project_types.each do |sub_type|
          # use entry closest to report start for client metadata see docs/Introductory-Guide-to-the-2016-AHAR Page 9
          first_entry = first_entry_in_category(id, sub_type)
          age = first_entry[service_history_age_index] || infer_adulthood(id)
          @answers[sub_type][age_range(age)] += 1
          @support[sub_type][age_range(age)] ||= {}
          @support[sub_type][age_range(age)][:headers] ||= ['Client ID']
          @support[sub_type][age_range(age)][:counts] ||= []
          @support[sub_type][age_range(age)][:counts] << [id]
        end
      end
    end

    # No longer collected as of 2015
    #  def add_last_permanent_zip_answers
    #   entries_by_client_id.each do |id, entries|
    #     first_entry = entries.first
    #     age = first_entry[service_history_age_index]
    #     # Find the client's last permanent zip codes
    #     distinct_zip_codes = begin 
    #       entries.map do |m| 
    #         involved_enrollments_by_entry_id_and_data_source_id[[m[service_history_enrollment_group_id_index], m[service_history_data_source_id_index]]]
    #       end.map do |n|
    #         [m[service_history_project_type_index], n[enrollment_last_permanent_zip_index]]
    #       end.uniq.reject(&:empty?)
    #       # include only those within the CoC
    #       # (COC_ZIP_CODES & distinct_zip_codes)
    #     end
    #     # count anyone with a last permanent zip in the CoC, unless they are in a family, then only count adults
    #     if distinct_zip_codes.any?
    #       family = family_members.include?(id)

    #     end
    #   end
    # end
    
    def veteran_slug code 
      case code 
      when 1
        'Vet'
      when 99
        'Vet_Mx'
      else
        'NVet'
      end
    end

    def lts_disability id
      disability_slug(entries_by_client_id[id])
    end

    def prior_living_length_slug length_code
      return 'Mx' unless length_code.present?
      case length_code
      when 10, 11
        '1_Wk_LE'
      when 2
        'G_Wk_L_Mnt'
      when 3
        '1_3_Mnt'
      when 4
        'G_3_Mt_L_Yr'
      when 5
        '1_Yr_GE'
      else
        'Mx'
      end
    end

    def race_slug client
      multi = 0
      slug = 'Mx' # Unknown
      if client[client_am_ind_ak_native_index] == 1
        slug = 'Amer_Ind_Alask'
        multi += 1
      end
      if client[client_asian_index] == 1
        slug = 'Asian'
        multi += 1
      end
      if client[client_black_index] == 1
        slug = 'Black'
        multi += 1
      end
      if client[client_native_hi_index] == 1
        slug = 'Nat_Haw_Oth_Pac'
        multi += 1
      end
      if client[client_white_index] == 1 
        if client[client_ethnicity_index] == 1 # Hispanic/Latino
          slug = 'Wh_His_Lat'
        else
          slug = 'Wh_NHis_NLat'
        end
        multi += 1
      end
      if multi > 1
        slug = 'Multi'
      end
      return slug
    end

    def prior_living_situation_slug prior_living_situation
      "Lvn_B4_Prg_Ent_#{living_situation_code(prior_living_situation)}"
    end

    def household_size_slug size
      if size == 1
        'HH_Size_1'
      elsif size == 2
        'HH_Size_2'
      elsif size == 3
        'HH_Size_3'
      elsif size == 4
        'HH_Size_4'
      elsif size >= 5
        'HH_Size_5_GE'
      else
        'HH_Size_Mx'
      end
    end

    def gender_slug client_id, first_entry
      gender = client_metadata_by_client_id[client_id][client_gender_index]
      "Gnd_#{stage_in_life(client_id, first_entry)}_#{gender_code(gender, true).gsub('_Gnd', '')}"
    end

    # Figure out if we were disabled by looking for the first entry where we gave a yes or no
    def disability_slug entries
      entries.each do |entry|
        client_id = entry[service_history_client_id_index]
        enrollment_group_id = entry[service_history_enrollment_group_id_index]
        data_source_id = entry[service_history_data_source_id_index]
        # Default to unknown
        disability_status = 'Disabled_Mx'
        # If we answerd Universal Data Element: 3.8 Disabling Condition, use that
        if involved_enrollments_by_entry_id_and_data_source_id[[enrollment_group_id, data_source_id]].present?
          disability_status = HUD::no_yes_reasons_for_missing_data(involved_enrollments_by_entry_id_and_data_source_id[[enrollment_group_id, data_source_id]][enrollment_disabling_condition_index])         
        end
        # Override the previous answer with a YES if:
        # Disability type = Substance Abuse (10)
        # Data element 4.10 is ‘Alcohol abuse’ or ‘Drug abuse’ or ‘Both alcohol and drug abuse’ [1,2,3]
        # and Expected to be of long-continued duration and substantially impairs ability to live independently is also ‘Yes,’ (IndefiniteAndImpairs == 1)
        if disabilities_by_client_id[client_id].present?
          disabilities = disabilities_by_client_id[client_id].select do |m|
            disability_type = m[disability_disability_type_index]
            long_term = m[disability_indefinite_and_impairs_index]
            response = m[disability_disability_response_index]
            disability_type == 10 && [1,2,3].include?(response) && long_term ==1
          end
          disability_status = 'Yes' if disabilities.any?
        end
        # Short circuit if we know the answer
        if disability_status == 'Yes'
          return 'Disabled_Yes'
        elsif disability_status == 'No'
          return 'Disabled_No'
        end
      end
      # If we didn't find a yes or a know, then we don't know   
      return 'Disabled_Mx'
    end

    # Based on HUD 1.3 HUD#disability_type and HUD#disability_response
    # If the type is 10, refer to the substance abuse list (4.10.2 DisabilityResponse)
    # Otherwise use 1.8 No/Yes/Reasons for Missing Data (hint: only 1 is yes)
    def disability_type_slug(entry)
      type = entry[disability_disability_type_index]
      response = entry[disability_disability_response_index]
      # ignore any responses that indicate nothing
      if [0,8,9,99].include?(response)
        return nil
      end
      case type
        when 5 then 'Phys_Dis'
        when 6 then 'Dev_Dis'
        when 7 then 'MX'
        when 8 then 'HIV_AIDS'
        when 9 then 'Ment_Health'
        when 10 then 'Sub_Abuse' # 1,2,3 responses all indicate substance abuse
      end
    end

    def ethnicity_slug ethnicity_code
      ethnicity = HUD::ethnicity(ethnicity_code)
      if ethnicity == 'Non-Hispanic/Non-Latino'
        'Ethn_NHis_NLat'
      elsif ethnicity == 'Hispanic/Latino'
        'Ethn_His_Lat'
      else
        'Ethn_Mx'
      end
    end
    
    def sub_type project_type, family
      suffix = 'IND'
      if family
        suffix = 'FAM'
      end
      case project_type
      when *PH
       "PSH-#{suffix}"
      when *TH
        "TH-#{suffix}"
      when *ES
        "ES-#{suffix}"
      end
    end

    def add_length_of_stay_answers
      length_of_stay_per_id_by_project_type.each do |client_id, sub_types|
        next unless vet_check(client_id: client_id)
        sub_types.each do |sub_type, dates_of_stay|
          if client_has_entry_in_sub_type(client_id, sub_type)
            first_entry = first_entry_in_category(client_id, sub_type)
            @answers[sub_type][length_of_stay_category(client_id, dates_of_stay, first_entry)] += 1
          end
        end
      end
    end

    protected def first_entry_in_category client_id, sub_type
      entries = entries_by_client_id[client_id]
      case sub_type
      when 'PSH-FAM'
        entries.select do |entry|
          PH.include?(entry[service_history_project_type_index]) && entry_belongs_to_family(entry)
        end.first
      when 'PSH-IND'
        entries.select do |entry|
          PH.include?(entry[service_history_project_type_index]) && ! entry_belongs_to_family(entry)
        end.first
      when 'ES-FAM'
        entries.select do |entry|
          ES.include?(entry[service_history_project_type_index]) && entry_belongs_to_family(entry)
        end.first
      when 'ES-IND'
        entries.select do |entry|
          ES.include?(entry[service_history_project_type_index]) && ! entry_belongs_to_family(entry)
        end.first
      when 'TH-FAM'
        entries.select do |entry|
          TH.include?(entry[service_history_project_type_index]) && entry_belongs_to_family(entry)
        end.first
      when 'TH-IND'
        entries.select do |entry|
          TH.include?(entry[service_history_project_type_index]) && ! entry_belongs_to_family(entry)
        end.first
      end
    end

    protected def psh_length_of_stay_category days      
      case days
      when (1..180)
        '1_180'
      when (181..365)
        '181_365'
      when (366..545)
        '366_545'
      when (546..730)
        '546_730'
      when (731..1825)
        '731_1825'
      when (1826..99999999999999999)
        '1826_GE'
      else
        'Mx'
      end
    end

    protected def length_of_stay_category client_id, days, first_entry
      # Limit days to 365 since that's the reporting window
      days.size = 365 if days.size > 365 

      gender = gender_code(client_metadata_by_client_id[client_id][client_gender_index], false)
      life_stage = stage_in_life(client_id, first_entry)
      
      suffix = case days.size
      when (1..7)
        '1_7'
      when (8..30)
        '8_30'
      when (31..60)
        '31_60'
      when (61..90)
        '61_90'
      when (91..120)
        '91_120'
      when (121..150)
        '121_150'
      when (151..180)
        '151_180'
      when (181..210)
        '181_210'
      when (211..240)
        '211_240'
      when (241..270)
        '241_270'
      when (271..300)
        '271_300'
      when (301..330)
        '301_330'
      when (331..360)
        '331_360'
      when (361..365)
        '361_365'
      else
        'Mx'
      end
      
      "#{life_stage}_#{gender}_Nt_#{suffix}"
    end

    # Taken from HUD::living_situation to provide correct slugs
    def living_situation_code(id)
      case id
        when 1 then 'ES'
        when 2 then 'TH'
        when 3 then 'PSH'
        when 4 then 'Psych'
        when 5 then 'SAbse'
        when 6 then 'Hsptl'
        when 7 then 'Jail'
        when 8 then 'Mx'
        when 9 then 'Mx'
        when 12 then 'Fam'
        when 13 then 'Fren'
        when 14 then 'Hotel'
        when 15 then 'Foster'
        when 16 then 'N_4_Hbt'
        when 17 then 'Oth'
        when 18 then 'SH'
        when 19 then 'Rent_VS'
        when 20 then 'Rent_Oth_S'
        when 21 then 'Own_NS'
        when 22 then 'Rent_NS'
        when 23 then 'Own_S'
        when 24 then 'Rent_Oth_S'
        when 25 then 'Rent_Oth_S'
        when 26 then 'Oth'
        when 27 then 'Oth'
        when 99 then 'Mx'
        else 'Mx'
      end
    end

    # Taken from HUD::destination to provide correct slugs
    def destination_code(id)
      case id
        when 1 then 'ES'
        when 2 then 'TH'
        when 3 then 'PSH'
        when 4 then 'Psych'
        when 5 then 'SAbse'
        when 6 then 'Hsptl'
        when 7 then 'Jail'
        when 8 then 'Mx'
        when 9 then 'Mx'
        when 10 then 'Rent_NS'
        when 11 then 'Own_NS'
        when 12 then 'Fam_Temp'
        when 13 then 'Fren_Temp'
        when 14 then 'Hotel'
        when 15 then 'Foster'
        when 16 then 'N_4_Hbt'
        when 17 then 'Oth'
        when 18 then 'SH'
        when 19 then 'Rent_VS'
        when 20 then 'Rent_Oth_S'
        when 21 then 'Own_WS'
        when 22 then 'Fam_Perm'
        when 23 then 'Fren_Perm'
        when 24 then 'D'
        when 25 then 'Rent_Oth_S'
        when 26 then 'PSH'
        when 27 then 'TH'
        when 28 then 'Rent_Oth_S'
        when 29 then 'Oth'
        when 99 then 'Mx'
        else 'Mx'
      end
    end

    def gender_code gender_number, with_trans
      gender = case HUD::gender(gender_number)
      when 'Female'
        'F'
      when 'Male'
        'M'
      when 'Transgender male to female'
        'TMF'
      when 'Transgender female to male'
        'TFM'
      else
        'Mx_Gnd'
      end
      if ! with_trans
        if gender == 'TMF' || gender == 'TFM'
          gender = gender.last
        end
      end
      return gender
    end

    def stage_in_life client_id, first_entry
      age = first_entry[service_history_age_index] || infer_adulthood(client_id)
      if age.present? && age < ADULT
        'C'
      else
        'A'
      end
    end

    # FIXME? This should look at service per client, not entries
    # {1 => {PSH-FAM: 10, ES-FAM: 30}}
    def length_of_stay_per_id_by_project_type
      @length_of_stay_per_id_by_project_type ||= {}.tap do |m|
        entries_by_client_id.each do |id, entries|
          # setup counts by sub-type per client, default 0
          m[id] = SUB_TYPES.map{|m| [m, Set.new]}.to_h
          # Count by service history, not start & end dates
          entries.each do |e|
            days = dates_served_during_enrollment(entry: e)
            project_type = e[service_history_project_type_index]
            family = entry_belongs_to_family(e)           
            # Avoid double countingdays within one project type
            m[id][sub_type(project_type, family)] += days
          end
        end
      end
    end

    def dates_served_during_enrollment entry:
      (client_id, enrollment_group_id) = entry.values_at(service_history_client_id_index, service_history_enrollment_group_id_index)
      @dates_by_client_id_enrollment_id ||= begin
        fields = [:date, :client_id, :enrollment_group_id]
        involved_entries_scope.where(
          date: (@report_start...@report_end),
          record_type: 'service'
        ).
        pluck(*fields).
        map do |row|
          fields.zip(row).to_h
        end.
        group_by do |m|
          [m[:client_id], m[:enrollment_group_id]]
        end    
      end
      return [] unless @dates_by_client_id_enrollment_id[[client_id, enrollment_group_id]].present?
      @dates_by_client_id_enrollment_id[[client_id, enrollment_group_id]].map{|m| m[:date]}
    end

    def lts_age_range age
      slug = age_range(age)
      if slug == 'Age_51_61' || slug == 'Age_62_GE'
        slug = 'Age_51_GE'
      elsif slug == 'Age_18_24' || slug == 'Age_25_30'
        slug = 'Age_18_30'
      end
      return slug
    end

    def age_range age
      return 'Age_Mx' unless age.present?
      if age < 1
        'Age_LT_1'
      elsif age >= 1 && age <= 5 
        'Age_1_5'
      elsif age >= 6 && age <= 12
        'Age_6_12'
      elsif age >= 13 && age <= 17
        'Age_13_17'
      elsif age >= 18 && age <= 24
        'Age_18_24'
      elsif age >= 25 && age <= 30
        'Age_25_30'
      elsif age >= 31 && age <= 50
        'Age_31_50'
      elsif age >= 51 && age <= 61
        'Age_51_61'
      elsif age >= 62
        'Age_62_GE'
      end
    end

    def households
      @households ||= {}.tap do |m|
        first_entries_by_household_id.each do |k, entries|
          (household_id, _, _) = k
          child = 0
          adult = 0
          gender_individual = nil
          data_source_id = nil
          project_id = nil
          entries.each do |entry|
            age = entry[service_history_age_index] || infer_adulthood(entry[service_history_client_id_index])
            client_id = entry[service_history_client_id_index]
            gender_individual = gender_code(client_metadata_by_client_id[client_id][client_gender_index], false)
            data_source_id ||= entry[service_history_data_source_id_index]
            project_id ||= entry[service_history_project_id_index]
            if age.present? && age < ADULT
              child += 1
            else
              adult += 1
            end
          end
          size = child + adult
          family = child > 0 && adult > 0
          
          if child == 1 && adult == 0
            household_type = 'HH_Typ_UY' # Unaccompanied child presenting as an individual
          elsif child > 1 && adult == 0
            household_type = 'HH_Typ_C_Only' # Children Only
          else
            household_type = 'HH_Typ_A_Only' # Adults only
          end

          if child == 0 && adult == 0
            puts entries.inspect
          end
          m[[household_id, data_source_id, project_id]] = {size: size, child: child, adult: adult, family: family, household_type: household_type}
        end
      end.except(nil, '')
    end

    def entry_belongs_to_family entry
      hh_id = entry[service_history_household_id_index]
      ds_id = entry[service_history_data_source_id_index]
      project_id = entry[service_history_project_id_index]
      households[[hh_id, ds_id, project_id]].try(:[], :family) || false
    end

    def clients_by_sub_type
      @clients_by_sub_type ||= begin 
        by_sub_type = SUB_TYPES.map{|m| [m, Set.new]}.to_h
        entries_by_client_id.each do |id, entries|
          entries.map.each do |entry|
            family = entry_belongs_to_family(entry)
            project_type = entry[service_history_project_type_index]
            by_sub_type[sub_type(project_type, family)] << id
          end
        end
        by_sub_type
      end
    end

    def client_has_entry_in_sub_type client_id, sub_type
      clients_by_sub_type[sub_type].include?(client_id)
    end

    def involved_entries_scope
       # make sure we include any project that is acting as one of our housing related projects
      GrdaWarehouse::ServiceHistory.joins(:project).where("(first_date_in_program <= ? and last_date_in_program >= ? ) or (first_date_in_program <= ? and last_date_in_program is null) or (first_date_in_program >= ? and first_date_in_program <= ?)", @report_start, @report_start, @report_start, @report_start, @report_end).where("(Project.act_as_project_type in (#{(PH + TH + ES).join(', ')})) or (project_type in (#{(PH + TH + ES).join(', ')}) and Project.act_as_project_type is null)")
    end

    def involved_entries
      @involved_entries ||= involved_entries_scope.where(record_type: 'entry').order(first_date_in_program: :asc).pluck(*sh_cols)
      #involved_entries_scope.where(record_type: 'entry').order(first_date_in_program: :asc).joins(:project).select(*(service_history_columns - [:project_type])).select("isNull(Project.act_as_project_type, warehouse_client_service_history.project_type) as project_type")
    end

    # load HUD Enrollments associated with entries for additional data bits
    def involved_enrollments_by_entry_id_and_data_source_id
      @involved_enrollments_by_entry_id_and_data_source_id ||= begin
        {}.tap do |m|
          project_entries = involved_entries.map{|m| m[service_history_enrollment_group_id_index]}
          project_entries.each_slice(5000) do |entries|
            m.merge!(GrdaWarehouse::Hud::Enrollment.where(ProjectEntryID: entries).pluck(*enrollment_columns).index_by do |m| 
              [m[enrollment_project_entry_id_index], m[enrollment_data_source_id_index]]
            end)
          end
        end
      end
    end

    # Find any clients who were served by ES, PSH, TH between 10/1/2015 and 9/30/2016
    def entries_by_client_id
      @entries_by_client_id ||= involved_entries.group_by do |m|
        m[service_history_client_id_index]
      end
    end

    # group all entries by household ID, group those by date, keep only those from the first date
    def first_entries_by_household_id
      @first_entries_by_household_id ||= begin
        entries_by_household_id = involved_entries.group_by do |m|
          hh_id = m[service_history_household_id_index]
          ds_id = m[service_history_data_source_id_index]
          project_id = m[service_history_project_id_index]
          [hh_id, ds_id, project_id] if hh_id.present?
        end.except(nil, '').map do |k, entries|
          (hh_id, ds_id, project_id) = k
          [k, entries.group_by{|m| m[service_history_first_date_in_program_index]}.values.first]
        end.to_h
      end
    end

    # families have a minimum of one person 18 or older and one under 18
    def ids_of_families
      @ids_of_families ||= [].tap do |m|
        first_entries_by_household_id.each do |_, entries|
          if entries.size > 1
            zero_to_18 = 0
            eightteen_or_older = 0
            entries.each do |c|
              age = c[service_history_age_index] || infer_adulthood(c[service_history_client_id_index])
              zero_to_18 += 1 if age.present? && age < ADULT
              eightteen_or_older += 1 if age.present? && age >= ADULT
            end
            if zero_to_18 > 0 && eightteen_or_older > 0
              m << entries.map{|entry| entry[service_history_client_id_index]}
            end
          end
        end
      end
    end

    def vet_check(client_id:)
      return true unless vets_only
      all_vets.include?(client_id)
    end

    # get everyone flagged as VeteranStatus = 1 and attempt to limit them 
    # to people who were 18 in their first enrollment within scope
    def all_vets
      @all_vets ||= client_metadata_by_client_id.select do |id, data|
        first_age = entries_by_client_id[id].first[service_history_age_index]
        data[client_veteran_status_index] == 1 && (first_age.blank? || first_age >= ADULT)
      end.keys
    end

    def infer_adulthood client_id
      first_entry_date = entries_by_client_id[client_id].first[service_history_first_date_in_program_index]
      if first_entry_date < Date.today - 18.years # happened over 18 years ago
        return ((Date.today - first_entry_date)/365).to_i
      end
      return nil
    end

    def client_metadata_by_client_id
      @client_metadata_by_client_id ||= begin
        {}.tap do |m|
          entries_by_client_id.keys.each_slice(5000) do |ids|
            m.merge!(GrdaWarehouse::Hud::Client.where(id: ids).pluck(*client_columns).index_by{|m| m[client_id_index]})
          end
        end
      end
    end

    def client_id_by_source_client_personal_id_and_data_source
      @client_id_by_source_client_personal_id_and_data_source ||= begin
        {}.tap do |m|
          entries_by_client_id.keys.each_slice(5000) do |ids|
            m.merge!(GrdaWarehouse::WarehouseClient.where(destination_id: ids).pluck(:id_in_source, :destination_id, :data_source_id).map{|m| [[m.first, m.last], m.second]}.to_h)
          end
        end
      end
    end

    def disabilities_by_client_id
      @disabilities_by_client_id ||= begin
        {}.tap do |m|
          client_id_by_source_client_personal_id_and_data_source.keys.each_slice(5000) do |ids|
            p_ids = ids.map(&:first)
            m.merge!(GrdaWarehouse::Hud::Disability.where(PersonalID: p_ids).pluck(*disability_columns).group_by do |m|
              # group them by their destination client id
              client_id_by_source_client_personal_id_and_data_source[[m[disability_personal_id_index], m[disability_data_source_id_index]]]
              end){|k,v1,v2| v1 + v2} # merge by adding arrays together 
          end
        end              
      end
    end

    #  def project_types_by_project_id_and_data_source_id
    #   @project_types_by_project_id_and_data_source_id ||= GrdaWarehouse::Hud::Project.where.not(act_as_project_type: nil).where(act_as_project_type: (PH + TH + ES)).pluck(*project_columns).map{|m| [[m[project_project_id_index],m[project_data_source_id_index]], m[project_act_as_project_type_index]] }.to_h
    # end

    #  def project_columns
    #   [
    #     :ProjectID,
    #     :data_source_id,
    #     :act_as_project_type,
    #   ]
    # end
    
    def act_as_project_overlay
      pt = GrdaWarehouse::Hud::Project.arel_table
      st = GrdaWarehouse::ServiceHistory.arel_table
      nf( 'COALESCE', [ pt[:act_as_project_type], st[:project_type] ] ).as('project_type').to_sql
    end

    def sh_cols 
      service_history_columns.map{|m| m == :project_type ? act_as_project_overlay : m}
    end

    def service_history_columns
      [
        :client_id, 
        :data_source_id, 
        :date, 
        :first_date_in_program, 
        :last_date_in_program, 
        :enrollment_group_id, 
        :age, 
        :destination, 
        :head_of_household_id,
        :household_id, 
        :project_id, 
        :project_name, 
        :project_type, 
        :project_tracking_method, 
        :organization_id, 
        :record_type, 
        :housing_status_at_entry, 
        :housing_status_at_exit, 
        :service_type,
      ]
    end

    def client_columns
      [
        :PersonalID, 
        :data_source_id, 
        :Gender, 
        :VeteranStatus,
        :Ethnicity,
        :AmIndAKNative,
        :Asian,
        :BlackAfAmerican,
        :NativeHIOtherPacific,
        :White,
        :RaceNone,
        :id,
      ]
    end

    def enrollment_columns
      [
        :ProjectEntryID, 
        :data_source_id, 
        :ResidencePrior, 
        :ResidencePriorLengthOfStay,
        :DisablingCondition,
        :LastPermanentZIP, 
        :id,
      ]
    end

    def disability_columns
      [
        :DisabilityType,
        :DisabilityResponse,
        :IndefiniteAndImpairs,
        :PersonalID,
        :data_source_id,
      ]
    end

    #  def project_project_id_index
    #   @project_project_id_index ||= project_columns.find_index(:ProjectID)
    # end

    #  def project_data_source_id_index
    #   @project_data_source_id_index ||= project_columns.find_index(:data_source_id)
    # end

    #  def project_act_as_project_type_index
    #   @project_act_as_project_type_index ||= project_columns.find_index(:act_as_project_type)
    # end

    def service_history_client_id_index
      @service_history_client_id_index ||= service_history_columns.find_index(:client_id)
    end

    def service_history_household_id_index
      @service_history_household_id_index ||= service_history_columns.find_index(:household_id)
    end

    def service_history_age_index
      @service_history_age_index ||= service_history_columns.find_index(:age)
    end

    def service_history_project_type_index
      @service_history_project_type_index ||= service_history_columns.find_index(:project_type)
    end

    def service_history_project_id_index
      @service_history_project_id_index ||= service_history_columns.find_index(:project_id)
    end

    def service_history_project_name_index
      @service_history_project_name_index ||= service_history_columns.find_index(:project_name)
    end

    def service_history_first_date_in_program_index
      @service_history_first_date_in_program_index ||= service_history_columns.find_index(:first_date_in_program)
    end

    def service_history_last_date_in_program_index
      @service_history_last_date_in_program_index ||= service_history_columns.find_index(:last_date_in_program)
    end

    def service_history_enrollment_group_id_index
      @service_history_enrollment_group_id_index ||= service_history_columns.find_index(:enrollment_group_id)
    end

    def service_history_data_source_id_index
      @service_history_data_source_id_index ||= service_history_columns.find_index(:data_source_id)
    end

    def service_history_destination_index
      @service_history_destination_index ||= service_history_columns.find_index(:destination)
    end

    def client_am_ind_ak_native_index
      @client_am_ind_ak_native_index ||= client_columns.find_index(:AmIndAKNative)
    end

    def client_asian_index
      @client_asian_index ||= client_columns.find_index(:Asian)
    end

    def client_black_index
      @client_black_index ||= client_columns.find_index(:BlackAfAmerican)
    end

    def client_native_hi_index
      @client_native_hi_index ||= client_columns.find_index(:NativeHIOtherPacific)
    end

    def client_white_index
      @client_white_index ||= client_columns.find_index(:White)
    end

    def client_id_index
      @client_id_index ||= client_columns.find_index(:id)
    end

    def client_gender_index
      @client_gender_index ||= client_columns.find_index(:Gender)
    end

    def client_ethnicity_index
      @client_ethnicity_index ||= client_columns.find_index(:Ethnicity)
    end

    def client_veteran_status_index
      @client_veteran_status_index ||= client_columns.find_index(:VeteranStatus)
    end

    def enrollment_project_entry_id_index
      @enrollment_project_entry_id_index ||= enrollment_columns.find_index(:ProjectEntryID)
    end

    def enrollment_data_source_id_index
      @enrollment_data_source_id_index ||= enrollment_columns.find_index(:data_source_id)
    end

    def enrollment_disabling_condition_index
      @enrollment_disabling_condition_index ||= enrollment_columns.find_index(:DisablingCondition)
    end

    def enrollment_last_permanent_zip_index
      @enrollment_last_permanent_zip_index ||= enrollment_columns.find_index(:LastPermanentZIP)
    end

    def enrollment_prior_residence_index
      @enrollment_prior_residence_index ||= enrollment_columns.find_index(:ResidencePrior)
    end

    def enrollment_prior_residence_length_of_stay_index
      @enrollment_prior_residence_length_of_stay_index ||= enrollment_columns.find_index(:ResidencePriorLengthOfStay)
    end

    def disability_personal_id_index
      @disability_personal_id_index ||= disability_columns.find_index(:PersonalID)
    end

    def disability_data_source_id_index
      @disability_data_source_id_index ||= disability_columns.find_index(:data_source_id)
    end

    def disability_disability_type_index
      @disability_disability_type_index ||= disability_columns.find_index(:DisabilityType)
    end

    def disability_disability_response_index
      @disability_disability_response_index ||= disability_columns.find_index(:DisabilityResponse)
    end

    def disability_indefinite_and_impairs_index
      @disability_indefinite_and_impairs_index ||= disability_columns.find_index(:IndefiniteAndImpairs)
    end
    

  end
end