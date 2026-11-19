# ==============================================================================
# Alzheimer's Disease Memory Task Analysis in R
# Author: Gerasimos Kapouranis
# Description:
#   Exploratory data analysis and two-sample t-tests comparing visual memory
#   performance (Colour-Shape and Grey-Shape tasks) between Alzheimer's patients
#   (n = 45) and healthy controls (n = 45), including an examination of age
#   and gender differences across groups.
# ==============================================================================

# Create output folders if they do not exist
dir.create("results", showWarnings = FALSE, recursive = TRUE)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

# 1. Load and inspect the dataset ----------------------------------------------
data <- read.csv(file.path("data", "AlzheimersData.csv"), stringsAsFactors = FALSE)

dim(data)          # 90 rows, 6 columns
str(data)          # Variable types
sum(is.na(data))   # Check for missing values (0)

# Create a readable group label for tables and plots
data$Group <- ifelse(data$AlzheimersDisease, "Alzheimer's Disease", "Healthy Controls")

# 2. Check sample balance (Diagnosis & Gender) ---------------------------------
cat("\n=== SAMPLE BALANCE ===\n")
print(table(Diagnosis = data$Group))
print(table(Diagnosis = data$Group, Gender = data$Gender))

# 3. Summary statistics overall and by group -----------------------------------
cat("\n=== OVERALL SUMMARY ===\n")
print(summary(data[, c("Age", "ColourShapeCorrect", "GreyShapeCorrect")]))

alz <- subset(data, AlzheimersDisease == TRUE)
ctrl <- subset(data, AlzheimersDisease == FALSE)

cat("\n=== ALZHEIMER'S DISEASE GROUP (n = 45) ===\n")
print(summary(alz[, c("Age", "ColourShapeCorrect", "GreyShapeCorrect")]))

cat("\n=== HEALTHY CONTROLS GROUP (n = 45) ===\n")
print(summary(ctrl[, c("Age", "ColourShapeCorrect", "GreyShapeCorrect")]))

# Save clean summary table to CSV
vars <- c("Age", "ColourShapeCorrect", "GreyShapeCorrect")
summary_list <- list()
idx <- 1
for (v in vars) {
  for (g in c("Healthy Controls", "Alzheimer's Disease")) {
    vals <- data[data$Group == g, v]
    summary_list[[idx]] <- data.frame(
      Variable = v,
      Group = g,
      Count = length(vals),
      Mean = round(mean(vals), 1),
      SD = round(sd(vals), 1),
      Median = round(median(vals), 1),
      Min = min(vals),
      Max = max(vals)
    )
    idx <- idx + 1
  }
}
group_summary <- do.call(rbind, summary_list)
write.csv(group_summary, file.path("results", "group_summary.csv"), row.names = FALSE)

# 4. Two-sample t-tests (comparing Healthy Controls vs. Alzheimer's) -----------
cat("\n=== TWO-SAMPLE T-TESTS ===\n")
t_colour <- t.test(ctrl$ColourShapeCorrect, alz$ColourShapeCorrect)
t_grey   <- t.test(ctrl$GreyShapeCorrect,   alz$GreyShapeCorrect)
t_age    <- t.test(ctrl$Age,                alz$Age)

print(t_colour)
print(t_grey)
print(t_age)

ttest_results <- data.frame(
  Variable = c("Colour-Shape Task", "Grey-Shape Task", "Age (Years)"),
  Healthy_Mean = round(c(mean(ctrl$ColourShapeCorrect), mean(ctrl$GreyShapeCorrect), mean(ctrl$Age)), 1),
  Alzheimers_Mean = round(c(mean(alz$ColourShapeCorrect), mean(alz$GreyShapeCorrect), mean(alz$Age)), 1),
  Difference_Healthy_minus_AD = round(c(
    mean(ctrl$ColourShapeCorrect) - mean(alz$ColourShapeCorrect),
    mean(ctrl$GreyShapeCorrect) - mean(alz$GreyShapeCorrect),
    mean(ctrl$Age) - mean(alz$Age)
  ), 1),
  CI_95_Low = round(c(t_colour$conf.int[1], t_grey$conf.int[1], t_age$conf.int[1]), 1),
  CI_95_High = round(c(t_colour$conf.int[2], t_grey$conf.int[2], t_age$conf.int[2]), 1),
  t_statistic = round(c(t_colour$statistic, t_grey$statistic, t_age$statistic), 2),
  p_value = formatC(c(t_colour$p.value, t_grey$p.value, t_age$p.value), format = "e", digits = 2)
)
write.csv(ttest_results, file.path("results", "ttest_results.csv"), row.names = FALSE)

# 5. Visualisations (Boxplots & Scatterplot) -----------------------------------
# Plot 1: Task performance by group
png(file.path("figures", "01_task_performance_boxplots.png"), width = 1600, height = 750, res = 180)
par(mfrow = c(1, 2), mar = c(5, 4.5, 3.5, 1.5))
boxplot(ColourShapeCorrect ~ Group, data = data,
        col = c("#FBD5D5", "#D6E4F0"), border = c("#C53030", "#2B6CB0"),
        main = "Colour-Shape Memory Task", xlab = "", ylab = "Correct Trials")
boxplot(GreyShapeCorrect ~ Group, data = data,
        col = c("#FBD5D5", "#D6E4F0"), border = c("#C53030", "#2B6CB0"),
        main = "Grey-Shape Memory Task", xlab = "", ylab = "Correct Trials")
dev.off()

# Plot 2: Age distribution & score vs. age
png(file.path("figures", "02_age_and_performance.png"), width = 1600, height = 750, res = 180)
par(mfrow = c(1, 2), mar = c(5, 4.5, 3.5, 1.5))
boxplot(Age ~ Group, data = data,
        col = c("#FBD5D5", "#D6E4F0"), border = c("#C53030", "#2B6CB0"),
        main = "Participant Age by Group", xlab = "", ylab = "Age (Years)")

point_colors <- ifelse(data$AlzheimersDisease, "#C53030", "#2B6CB0")
plot(data$Age, data$ColourShapeCorrect, col = point_colors, pch = 19,
     main = "Colour-Shape Score vs. Age", xlab = "Age (Years)", ylab = "Correct Trials")
legend("topright", legend = c("Healthy Controls", "Alzheimer's Disease"),
       col = c("#2B6CB0", "#C53030"), pch = 19)
dev.off()

cat("\nDone! Results saved in 'results/' and plots saved in 'figures/'.\n")
