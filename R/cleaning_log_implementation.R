library(tidyverse)
library(lubridate)
library(glue)
library(supporteR)

# Read data and checking log 

log_loc <- "inputs/combined_ipe_logs_with_batch_name.xlsx"

log_col_types <- ifelse(str_detect(string = names(readxl::read_excel(path = log_loc, n_max = 1000)), pattern = "start_date|checked_date"), "date",  "text")

df_cleaning_log <- readxl::read_excel(log_loc, col_types = log_col_types) |> 
  filter(!adjust_log %in% c("delete_log"), reviewed %in% c("1")) |>
  mutate(adjust_log = ifelse(is.na(adjust_log), "apply_suggested_change", adjust_log),
         value = ifelse(is.na(value) & str_detect(string = issue_id, pattern = "logic_c_"), "blank", value),
         value = ifelse(type %in% c("remove_survey"), "blank", value),
         name = ifelse(is.na(name) & type %in% c("remove_survey"), "point_number", name)
  ) |> 
  filter(!is.na(value), !is.na(uuid)) |>
  mutate(value = ifelse(value %in% c("blank"), NA, value),
         sheet = NA,
         index = NA,
         relevant = NA) |>
  select(uuid, type, name, value, issue_id, sheet, index, relevant, issue)


# raw data
loc_data <- "inputs/Reach Household visit/Household visit 10 percent Survey_added_names.xlsx"

cols_to_escape <- c("index", "start", "end", "today", "starttime",	"endtime", "_submission_time", "_submission__submission_time",
                    "date_last_received")

data_nms <- names(readxl::read_excel(path = loc_data, n_max = 2000))
c_types <- ifelse(str_detect(string = data_nms, pattern = "_other$"), "text", "guess")

df_raw_data <- readxl::read_excel(path = loc_data, col_types = c_types) |> 
  mutate(across(.cols = -c(contains(cols_to_escape)), 
                .fns = ~ifelse(str_detect(string = ., 
                                          pattern = fixed(pattern = "N/A", ignore_case = TRUE)), "NA", .)))

# tool
loc_tool <- "inputs/Individual_Profiling_Exercise_Tool.xlsx"

df_survey <- readxl::read_excel(loc_tool, sheet = "survey")
df_choices <- readxl::read_excel(loc_tool, sheet = "choices")

# main dataset ------------------------------------------------------------

df_cleaning_log_main <-  df_cleaning_log |> 
  filter(is.na(sheet))

df_cleaned_data <- supporteR::cleaning_support(input_df_raw_data = df_raw_data,
                                               input_df_survey = df_survey,
                                               input_df_choices = df_choices,
                                               input_df_cleaning_log = df_cleaning_log_main) |> 
  mutate(across(.cols = -c(any_of(cols_to_escape), matches("_age$|^age_|uuid")),
                .fns = ~ifelse(str_detect(string = ., pattern = "^[9]{2,9}$"), "NA", .)))