library(tidyverse)

# load the data for aggregation
df_preloading_data <- read_csv("inputs/sample_data_for_hh_visit.csv")

# determine hh size
df_hh_size <- df_preloading_data %>% 
  group_by(Registration_Group) %>%
  summarise(hh_size = n())

# determine existence of age 6_12
df_hh_with_age_6_12 <- df_preloading_data %>% 
  filter(Age >= 6, Age <= 12) %>% 
  group_by(Registration_Group) %>%
  summarise(hh_age_6_12 = n())

# determine existence of age 13_16
df_hh_with_age_13_16 <- df_preloading_data %>% 
  filter(Age >= 13, Age <= 16) %>% 
  group_by(Registration_Group) %>%
  summarise(hh_age_13_16 = n())

# determine existence of a child
df_hh_with_age_to_18 <- df_preloading_data %>% 
  filter(Age <= 18) %>% 
  group_by(Registration_Group) %>%
  summarise(hh_age_to_18 = n())

# determine eligible age for mental health questions
df_hh_with_age_atleast_12 <- df_preloading_data %>% 
  filter(Age >= 12) %>% 
  group_by(Registration_Group) %>%
  summarise(hh_age_atleast_12 = n())

# join the aggregated fields to household data
df_data_with_extra_columns <- df_preloading_data %>% 
  distinct(Registration_Group, Settlement, Zone, Village) %>% 
  left_join(df_hh_size, by = "Registration_Group") %>% 
  left_join(df_hh_with_age_6_12, by = "Registration_Group") %>% 
  left_join(df_hh_with_age_13_16, by = "Registration_Group") %>% 
  left_join(df_hh_with_age_to_18, by = "Registration_Group") %>% 
  left_join(df_hh_with_age_atleast_12, by = "Registration_Group") %>% 
  mutate(hh_age_6_12 = ifelse(is.na(hh_age_6_12), 0, hh_age_6_12),
         hh_age_13_16 = ifelse(is.na(hh_age_13_16), 0, hh_age_13_16),
         hh_age_to_18 = ifelse(is.na(hh_age_to_18), 0, hh_age_to_18),
         hh_age_atleast_12 = ifelse(is.na(hh_age_atleast_12), 0, hh_age_atleast_12)
         )

# write the result to a file
write_csv(x = df_data_with_extra_columns, file = "outputs/hh_level_data.csv")