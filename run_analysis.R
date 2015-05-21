# A) dataset set-up
Url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(Url, destfile = "~/data/R/coursera/getting_cleaning_data/project/dataset.zip", method = "curl")
# manual file unzipping

gTest <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/test/X_test.txt")
gTrain <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/train/X_train.txt")
subTest <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/test/subject_test.txt")
subTrain <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/train/subject_train.txt")
actTest <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/test/y_test.txt")
actTrain <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/train/y_train.txt")
featNames <- read.table("~/data/R/coursera/getting_cleaning_data/project/Dataset/features.txt")

#################################
# B) 1) merge test and train 4) label the dataset

# set up of the Test sample
library(data.table)
setnames(gTest, old = names(gTest), new = featNames[,2]) # rename different measures columns
setnames(subTest, old = c("V1"), new = c("SubID")) # rename Subjects column
setnames(actTest, old = c("V1"), new = c("Activity")) # rename Activities column
dim(gTest);dim(subTest);dim(actTest)
test <- cbind(subTest, actTest, group = c(rep(0,2947)), gTest) # Subject identifier, activity identifier and the feature variables and clipped all toghether. An extra column called group allows for identifying test/train members
dim(test)

setnames(gTrain, old = names(gTrain), new = featNames[,2]) # rename different measures columns
setnames(subTrain, old = c("V1"), new = c("SubID")) # rename Subjects column
setnames(actTrain, old = c("V1"), new = c("Activity")) # rename Activities column
dim(gTrain);dim(subTrain);dim(actTrain)
train <- cbind(subTrain, actTrain, group = c(rep(1, 7352)), gTrain) # Same process followed for test
dim(train)

final <- rbind(test, train) # the test and the train datasets are merged together

#################################
# C) 3) label activities in the dataset

final$Activity <- factor(final$Activity, levels = c(1, 2, 3, 4, 5, 6), labels = c("WALKING", "WALKING-UPSTAIRS", "WALKING-DOWNSTAIRS", "SITTING", "STANDING", "LAYING"))

#################################
# D) 2) subsample mean and std

# there are three typologies of mean and std column names:
# 1) featureName-std()/featureName-mean()
# 2) featureNameMean)
# 3) featureName-std()-X/Y/Z/featureName-mean()-X/Y/Z

colNames <- c("SubID", "Activity", "group", as.character(featNames[,2]))
names(final) <- gsub("[(),-]", "", colNames)
subsample <- data.frame(final[1:2], final[((grepl("[Mm]ean", names(final))|grepl("std", names(final))))])

#################################
# E) 5) new dataset with averages

library(dplyr)
# process to obtain the data frame including means in subgroups
by_idSub <- group_by(subsample, SubID, Activity) # create the subgroups
cols <- names(by_idSub)[-c(1, 2)] # removes the column not including features
test <- sapply(cols, function(x) substitute(mean(x), list(x = as.name(x))))
finalSub <- data.frame(do.call(summarise, c(list(.data = by_idSub), test)))

# export the final dataset
write.table(finalSub, "~/data/R/coursera/getting_cleaning_data/project/final.txt", row.name = FALSE)

# alternative pipeline approach to obtain the new dataset
altfinalSub <- subsample %>% group_by( SubID, Activity) %>%  summarise_each(funs(mean))
