
# ============================================================
# Marketing Campaign Performance, Purchase Behaviour & Engagement Analysis
# Author: Blessed Chishorwa 
# Dataset: Kaggle Customer Personality Analysis
# File: marketing_campaign.csv (tab-separated)
# ============================================================

# ------------------------------------------------------------
# 0. LOAD PACKAGES AND DATA
# ------------------------------------------------------------

library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)

df <- read.delim("marketing_campaign.csv", sep = "\t")

# Removing duplicates
dim(df)
df <- df %>% distinct()

# ------------------------------------------------------------
# 1. DATA CLEANING
# ------------------------------------------------------------

# Converting customer enrolment date from DD-MM-YYYY to Date format
df <- df %>%
  mutate(Dt_Customer = dmy(Dt_Customer))

# Calculating customer tenure and age
df$Tenure_Days <- as.numeric(Sys.Date() - df$Dt_Customer)
df$Age <- year(Sys.Date()) - df$Year_Birth

# Imputing missing Income values using the median since income is skewed. 
df$Income[is.na(df$Income)] <- median(df$Income, na.rm = TRUE)

# Creating total spend and total purchase variables
df <- df %>%
  mutate(
    Total_Spend = MntWines +
      MntFruits +
      MntMeatProducts +
      MntFishProducts +
      MntSweetProducts +
      MntGoldProds,
    
    Total_Purchases = NumDealsPurchases +
      NumWebPurchases +
      NumCatalogPurchases +
      NumStorePurchases
  )

# Creating a descriptive engagement flag based on purchase recency.
df <- df %>%
  mutate(
    Engagement_Flag = case_when(
      Recency > 80 ~ "High Recency - Low Engagement",
      Recency > 50 ~ "Medium Recency",
      TRUE ~ "Low Recency - Active"
    )
  )

# ------------------------------------------------------------
# 2. KPI CALCULATIONS
# ------------------------------------------------------------

# 1. Complaint rate
# Complain = customer made a complaint in the last 2 years
complaint_kpi <- df %>%
  summarise(
    Complaint_Rate = mean(Complain) * 100,
    Total_Complaints = sum(Complain),
    Total_Customers = n()
  )

print(complaint_kpi)

# 2. Campaign acceptance rates for the first five campaigns
campaign_kpi <- data.frame(
  Campaign = c("Cmp1", "Cmp2", "Cmp3", "Cmp4", "Cmp5"),
  Acceptance_Rate = c(
    mean(df$AcceptedCmp1),
    mean(df$AcceptedCmp2),
    mean(df$AcceptedCmp3),
    mean(df$AcceptedCmp4),
    mean(df$AcceptedCmp5)
  ) * 100
)

print(campaign_kpi)

# 3. Latest campaign response
# Response is analysed separately from the five earlier campaigns
response_kpi <- df %>%
  summarise(
    Last_Campaign_Rate = mean(Response) * 100,
    Last_Campaign_Accepted = sum(Response)
  )

print(response_kpi)

# 4. Share of recorded purchases by channel
channel_kpi <- df %>%
  summarise(
    Web_Share = sum(NumWebPurchases) / sum(Total_Purchases) * 100,
    Catalog_Share = sum(NumCatalogPurchases) / sum(Total_Purchases) * 100,
    Store_Share = sum(NumStorePurchases) / sum(Total_Purchases) * 100,
    Deals_Share = sum(NumDealsPurchases) / sum(Total_Purchases) * 100
  )

print(channel_kpi)

# Converting channel KPIs to long format for plotting
channel_long <- channel_kpi %>%
  pivot_longer(
    everything(),
    names_to = "Channel",
    values_to = "Rate"
  )

# 5. Complaint rate by marital status
complaint_by_marital <- df %>%
  group_by(Marital_Status) %>%
  summarise(
    Complaint_Rate = mean(Complain) * 100,
    Avg_Recency = mean(Recency),
    n = n()
  ) %>%
  arrange(desc(Complaint_Rate))

print(complaint_by_marital)

# 6. Complaint rate by education level
complaint_by_education <- df %>%
  group_by(Education) %>%
  summarise(
    Complaint_Rate = mean(Complain) * 100,
    Avg_Recency = mean(Recency),
    n = n()
  ) %>%
  arrange(desc(Complaint_Rate))

print(complaint_by_education)

# 7. Exploratory comparison of customers with and without complaints
engagement_comparison <- df %>%
  group_by(Complain) %>%
  summarise(
    Avg_Recency = mean(Recency),
    Avg_WebVisits = mean(NumWebVisitsMonth),
    Avg_Spend = mean(Total_Spend),
    Avg_Income = mean(Income),
    Count = n()
  )

print(engagement_comparison)

# ------------------------------------------------------------
# 3. VISUALISATIONS
# ------------------------------------------------------------

# Chart 1: Purchase recency by complaint status
p1 <- ggplot(
  df,
  aes(x = Recency, fill = as.factor(Complain))
) +
  geom_histogram(bins = 30, position = "identity", alpha = 0.7) +
  labs(
    title = "Purchase Recency by Complaint Status",
    subtitle = "Days since last purchase, grouped by complaint status",
    fill = "Complain",
    x = "Recency (days)",
    y = "Number of Customers"
  )

p1

# Chart 2: Acceptance rate for the five main campaigns
p2 <- ggplot(
  campaign_kpi,
  aes(x = reorder(Campaign, Acceptance_Rate), y = Acceptance_Rate)
) +
  geom_col(fill = "#2b5cff") +
  geom_text(
    aes(label = sprintf("%.2f%%", Acceptance_Rate)),
    hjust = -0.1,
    size = 3.5
  ) +
  coord_flip(
    ylim = c(0, max(campaign_kpi$Acceptance_Rate) * 1.3)
  ) +
  labs(
    title = "Campaign Acceptance Rate - Five Campaigns",
    subtitle = "Campaign 4 had the highest acceptance rate; Campaign 2 had the lowest",
    y = "Acceptance Rate (%)",
    x = "Campaign"
  )

p2

# Chart 3: Share of recorded purchases by channel
p3 <- ggplot(
  channel_long,
  aes(x = reorder(Channel, Rate), y = Rate)
) +
  geom_col(fill = "orange") +
  geom_text(
    aes(label = sprintf("%.1f%%", Rate)),
    hjust = -0.1,
    size = 3.5
  ) +
  coord_flip(
    ylim = c(0, max(channel_long$Rate) * 1.2)
  ) +
  labs(
    title = "Share of Recorded Purchases by Channel",
    subtitle = "Channel purchases as a share of total recorded purchases",
    y = "Share (%)",
    x = ""
  )

p3

# Chart 4: Monthly website visits by complaint status
p4 <- ggplot(
  df,
  aes(x = as.factor(Complain), y = NumWebVisitsMonth)
) +
  geom_boxplot(fill = "lightgreen") +
  labs(
    title = "Monthly Website Visits by Complaint Status",
    subtitle = "Comparison of customers who complained versus those who did not",
    x = "Complain (0 = No, 1 = Yes)",
    y = "Website Visits per Month"
  )

p4

# ------------------------------------------------------------
# 4. COMPLAINT PROBABILITY MODEL
# ------------------------------------------------------------

# Logistic regression to explore factors associated with complaints.
# This is exploratory and does not prove causation.
model <- glm(
  Complain ~ Recency + NumWebVisitsMonth + Total_Spend + Income,
  data = df,
  family = binomial
)

summary(model)

# Predict complaint probability for each customer
df$Complaint_Prob <- predict(model, type = "response") * 100

# Review the high-recency engagement group
high_recency_group <- df %>%
  filter(Engagement_Flag == "High Recency - Low Engagement") %>%
  select(
    ID,
    Recency,
    Engagement_Flag,
    NumWebVisitsMonth,
    Total_Spend,
    Complaint_Prob
  )

print(paste("High Recency (>80 days):", nrow(high_recency_group)))
print(head(high_recency_group))

# ------------------------------------------------------------
# 5. EXPORT OUTPUTS FOR POWER BI
# ------------------------------------------------------------

write.csv(df, "cleaned_marketing_for_powerbi.csv", row.names = FALSE)
write.csv(campaign_kpi, "campaign_kpi.csv", row.names = FALSE)
write.csv(response_kpi, "response_kpi.csv", row.names = FALSE)
write.csv(channel_kpi, "channel_kpi.csv", row.names = FALSE)
write.csv(complaint_kpi, "complaint_kpi.csv", row.names = FALSE)
