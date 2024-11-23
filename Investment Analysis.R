library(tidyverse)
library(tidyquant)
library(psych)
library(ggplot2)
library(dplyr)

library(readxl)
Energy_efficiency <- read_excel("C:/Users/SAMA BHAVASAR/OneDrive/SEM 2/MLB/Homework/Final assignment/Energy_Efficiency.xlsx")

reg_model <- lm(Cooling_load ~ Relative_Compactness + Surface_Area + Wall_Area + Roof_area + Overall_height + Orientation + Glazing_Area + Glazing_area_distribution,
                data = Energy_efficiency)

summary(reg_model)

reg_model_1 <- lm(Cooling_load ~ Relative_Compactness + Surface_Area + Wall_Area + Overall_height + Orientation + Glazing_Area + Glazing_area_distribution,
                  data = Energy_efficiency)
summary(reg_model_1)

#Binary variables

Energy_efficiency <- Energy_efficiency %>%
  mutate(Orientation.North = ifelse(Orientation == 2, 1,0)) %>%
  mutate(Orientation.East = ifelse(Orientation ==3,1,0)) %>%
  mutate(Orientation.West = ifelse(Orientation == 5,1,0))

Energy_efficiency <- Energy_efficiency %>%
  mutate(Glazing.Unknown = ifelse(Glazing_area_distribution == 0, 1,0)) %>%
  mutate(Glazing.Uniform = ifelse(Glazing_area_distribution ==1,1,0)) %>%
  mutate(Glazing.West = ifelse(Glazing_area_distribution == 5,1,0)) %>%
  mutate(Glazing.North = ifelse(Glazing_area_distribution == 2,1,0)) %>%
  mutate(Glazing.East = ifelse(Glazing_area_distribution == 3,1,0))

Energy_efficiency

reg_model_3 <- lm(Cooling_load ~ Relative_Compactness + Surface_Area + Wall_Area + Overall_height + Orientation.North + Orientation.East + Orientation.West + Glazing_Area + Glazing.Unknown + Glazing.East + Glazing.North + Glazing.West,
                  data = Energy_efficiency)
summary(reg_model_3)

library(car)
vif_model <- vif(reg_model_1)
print(vif_model)


energy_quartiles <- quantile(Energy_efficiency$Cooling_load, probs = c(0, 0.25, 0.50, 0.75, 1), na.rm = TRUE)

Energy_efficiency$Coolingquartile <- cut(Energy_efficiency$Cooling_load,
                                         breaks = energy_quartiles,
                                         labels = c("D", "C", "B", "A"),
                                         include.lowest = TRUE)
head(Energy_efficiency$Coolingquartile)
head(Energy_efficiency)


#SVM
library(e1071)
Energysubset <- Energy_efficiency[ , c("Relative_Compactness" , "Surface_Area", "Wall_Area", "Roof_area", "Overall_height", "Orientation", "Glazing_Area", "Glazing_area_distribution", 
                                       "Orientation.North", "Orientation.East", "Orientation.West", "Glazing.Unknown", "Glazing.East", "Glazing.North", "Glazing.West", "Coolingquartile")] 



library(caret)
set.seed(100)

train_index <- createDataPartition(Energysubset$Coolingquartile, p = 0.7, list = FALSE)
train_data <- Energysubset[train_index, ]
test_data <- Energysubset[-train_index, ]


svm_1 <- svm(Coolingquartile ~.,
             data = train_data)
summary(svm_1)

predictions <- predict(svm_1, test_data)
confusionMatrix(predictions, test_data$Coolingquartile)

library(e1071)
library(caret)
library(ggplot2)

# Assuming 'Energy_efficiency' is your original dataset and 'Coolingquartile' is your response variable.

# Preprocess the data: scale and center
preproc <- preProcess(Energy_efficiency, method = c("center", "scale"))

# Use PCA to reduce the dataset to 2 dimensions for visualization
pca_result <- predict(preproc, Energy_efficiency)
pca_result <- prcomp(pca_result, scale. = FALSE)

# Keep the first two principal components
pca_data <- as.data.frame(pca_result$Coolingquartile[,1:768])
pca_data$Coolingquartile <- Energy_efficiency$Coolingquartile

# Split the PCA-transformed data into training and testing sets
set.seed(100)
train_index <- createDataPartition(pca_data$Coolingquartile, p = 0.7, list = FALSE)
train_data_pca <- pca_data[train_index, ]
test_data_pca <- pca_data[-train_index, ]

# Train the SVM on the PCA-transformed data
svm_model_pca <- svm(Coolingquartile ~., data = train_data_pca)

# Predict on the PCA-transformed test data
predictions_pca <- predict(svm_model_pca, test_data_pca)

# Plot the decision boundary using ggplot2
ggplot(train_data_pca, aes(x = PC1, y = PC2, color = Coolingquartile)) +
  geom_point() +
  stat_contour(data = get_svm_data(svm_model_pca, train_data_pca), 
               aes(z = fitted), 
               breaks = 0.5, 
               linetype = "solid") +
  scale_color_manual(values = c("red", "blue")) +
  labs(title = "SVM Decision Boundary on PCA-transformed Data",
       x = "Principal Component 1", 
       y = "Principal Component 2", 
       color = "Cooling Quartile") +
  theme_minimal()

# Function to create a grid for plotting SVM decision boundary
get_svm_data <- function(model, data) {
  grid <- expand.grid(PC1 = seq(min(data$PC1), max(data$PC1), length.out = 100),
                      PC2 = seq(min(data$PC2), max(data$PC2), length.out = 100))
  grid$fitted <- predict(model, newdata = grid)
  return(grid)
}


####SVM##########

# Load necessary libraries
library(e1071)
library(ggplot2)

# Splitting data into training and test sets
set.seed(518)  # For reproducibility
index <- sample(1:nrow(Energy_efficiency), 0.6 * nrow(Energy_efficiency))
train_data <- Energy_efficiency[index, ]
test_data <- Energy_efficiency[-index, ]

# SVM model using all features
svm_model <- svm(Coolingquartile ~ ., data = train_data)
svm_model
summary(svm_model)

# Perform PCA on the training set, omitting the target variable and Cooling_load
pca <- prcomp(train_data[, !(names(train_data) %in% c("Coolingquartile", "Cooling_load"))], center = TRUE, scale. = TRUE)
train_data_pca <- data.frame(pca$x[, 1:2], Coolingquartile = train_data$Coolingquartile)

# Re-train SVM on the first two principal components for visualization
svm_pca <- svm(Coolingquartile ~ ., data = train_data_pca)

# Function to plot SVM decision boundaries for each quartile
plot_svm_for_quartile <- function(quartile, data, svm_model) {
  data_quartile <- subset(data, Coolingquartile == quartile)
  plot(svm_model, data_quartile, PC1 ~ PC2,
       main = sprintf("SVM Decision Boundary - Quartile '%s'", quartile),
       xlab = "Principal Component 1", ylab = "Principal Component 2")
}

# Setup plotting area for 4 plots (2x2 grid)
par(mfrow=c(2,2))

# Generate plots for each quartile
quartiles <- c("A", "B", "C", "D")
for (quartile in quartiles) {
  cat("\nPlotting SVM Decision Boundary for Quartile:", quartile, "\n")
  plot_svm_for_quartile(quartile, train_data_pca, svm_pca)
}

#PERCEPTRONS
library(nnet)  # For perceptrons
library(caret)  # For data splitting and accuracy computation
set.seed(123)  # For reproducibility

# Assuming the dataset is already loaded into 'data'
Energy_efficiency$Coolingquartile <- ifelse(Energy_efficiency$Coolingquartile %in% c("A", "B"), 1, -1)

accuracies <- c()  # To store accuracies of each model

for (i in 1:5) {
  # Split the data
  trainIndex <- createDataPartition(Energy_efficiency$Coolingquartile, p = 0.7, list = FALSE)
  train_data <- Energy_efficiency[trainIndex, ]
  test_data <- Energy_efficiency[-trainIndex, ]
  
  # Train the perceptron model
  perceptron_model <- nnet(Coolingquartile ~ ., data = train_data, size = 0, linout = TRUE, skip = TRUE, trace = FALSE, maxit = 1000)
  
  # Predict on test data
  predictions <- predict(perceptron_model, test_data, type = "class")
  
  # Calculate accuracy
  accuracy <- sum(predictions == test_data$Coolingquartile) / nrow(test_data)
  accuracies[i] <- accuracy
  cat("Model", i, "Accuracy:", accuracy, "\n")
}

# Report all accuracies
accuracies
accuracies
