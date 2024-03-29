library(tidyverse)
library(srvyr)
library(supporteR)

# source("R/composite_indicators.R")
source("R/make_weights.R")

# clean data
data_path <- "inputs/REACH DataPWD/combined_access_to_services_extract_ipe_verif_data.csv"

df_main_clean_data <- readr::read_csv(file =  data_path, col_types = cols(coping_less_expenditure = "c",
                                                                          primary_needs_top3 = "c",
                                                                          child_work_1217 = "c",
                                                                          coping_withdraw_school = "c",
                                                                          coping_withdraw_school_fhhh = "c",
                                                                          coping_withdraw_school_mhhh = "c",
                                                                          indv_medical_illness_3months = "c",
                                                                          indv_medical_illness_3months_sought_asst = "c",
                                                                          indv_difficulties_control_emotions = "c"))

# # question/choices codes and labels
df_choices <- readxl::read_excel("inputs/REACH DataPWD/Questions and Responses CODES.xlsx", sheet = "original") |> 
  mutate(choice_code = as.character(AnswerID),
         choice_label = as.character(Answer)) |> 
  select(choice_code, choice_label)

qn_label_lookup <- setNames(object = df_choices$choice_label, nm = df_choices$choice_code)

# df_tool_data_support <- df_survey |> 
#   select(type, name, label) |> 
#   filter(str_detect(string = type, pattern = "integer|date|select_one|select_multiple")) |> 
#   separate(col = type, into = c("select_type", "list_name"), sep =" ", remove = TRUE, extra = "drop" )

# 

# dap
dap <- read_csv("inputs/r_dap_ipe_access_services_verification.csv")
df_ref_pop <- read_csv("inputs/refugee_population_ipe.csv")

# make composite indicator ------------------------------------------------

df_with_composites <- df_main_clean_data |>  
  mutate(strata = paste0(settlement, "_refugee"))

# create weights ----------------------------------------------------------

# refugee weights
ref_weight_table <- make_refugee_weight_table(input_df_ref = df_with_composites, 
                                              input_refugee_pop = df_ref_pop)
df_ref_with_weights <- df_with_composites |>  
  left_join(ref_weight_table, by = "strata")


# set up design object ----------------------------------------------------

 
ref_svy <- as_survey(.data = df_ref_with_weights, strata = strata, weights = weights)


# analysis ----------------------------------------------------------------

df_main_analysis <- analysis_after_survey_creation(input_svy_obj = ref_svy,
                                                   input_dap = dap)
# merge analysis

combined_analysis <- df_main_analysis

# add labels
full_analysis_labels <- combined_analysis |> 
  mutate(variable = ifelse(is.na(variable) | variable %in% c(""), variable_val, variable),
         select_type = "select_one") |> 
  mutate(variable_val_label = recode(variable_val, !!!qn_label_lookup))
  # left_join(df_tool_data_support, by = c("int.variable" = "name")) |> 
  # relocate(label, .after = variable) |> 
  # mutate(select_type = case_when(int.variable %in% c("children_not_attending") ~ "integer",
  #                                int.variable %in% c("travel_time_primary", 
  #                                                    "travel_time_secondary",
  #                                                    "travel_time_clinic") ~ "select_one",
  #                                TRUE ~ select_type))

# convert to percentage
full_analysis_long <- full_analysis_labels |> 
  mutate(`mean/pct` = ifelse(select_type %in% c("integer") & !str_detect(string = variable, pattern = "^i\\."), `mean/pct`, `mean/pct`*100),
         `mean/pct` = round(`mean/pct`, digits = 2)) |> 
  select(`Question`= variable, 
         variable, 
         `choices/options` = variable_val, 
         `choices/options label` = variable_val_label, 
         `Results(mean/percentage)` = `mean/pct`, 
         n_unweighted, 
         population, 
         subset_1_name, 
         subset_1_val)

# output analysis
write_csv(full_analysis_long, paste0("outputs/", butteR::date_file_prefix(), "_full_analysis_lf_ipe_verification.csv"), na="")
