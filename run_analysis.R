# A) dataset set-up
Url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(Url, destfile="~/data/R/coursera/getting_cleaning_data/project/dataset.zip", method="curl")
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
setnames(gTest, old=names(gTest), new=featNames[,2]) # rename different measures columns
setnames(subTest, old=c("V1"), new=c("SubID")) # rename Subjects column
setnames(actTest, old=c("V1"), new=c("Activity")) # rename Activities column
dim(gTest);dim(subTest);dim(actTest)
test <- cbind(subTest, actTest, group=c(rep(0,2947)), gTest) # Subject identifier, activity identifier and the feature variables and clipped all toghether. An extra column called group allows for identifying test/train members
dim(test)

setnames(gTrain, old=names(gTrain), new=featNames[,2]) # rename different measures columns
setnames(subTrain, old=c("V1"), new=c("SubID")) # rename Subjects column
setnames(actTrain, old=c("V1"), new=c("Activity")) # rename Activities column
dim(gTrain);dim(subTrain);dim(actTrain)
train <- cbind(subTrain, actTrain, group=c(rep(1,7352)), gTrain) # Same process followed for test
dim(train)

final <- rbind(test, train) # the test and the train datasets are merged together

#################################
# C) 3) label activities in the dataset

final$Activity <- factor(final$Activity, levels=c(1,2,3,4,5,6), labels=c("WALKING","WALKING-UPSTAIRS","WALKING-DOWNSTAIRS","SITTING","STANDING","LAYING"))

#################################
# D) 2) subsample mean and std

library(stringr)
substrRight <- function(x, n){
        substr(x, nchar(x)-n+1, nchar(x))
} # function allowing to facilitate mean and std columns detection

substrRightAlt <- function(x, n){
        substr(x, start=0, nchar(x)-n)
}

# there are three typologies of mean and std column names:
# 1) featureName-std()/featureName-mean()
# 2) featureNameMean)
# 3) featureName-std()-X/Y/Z/featureName-mean()-X/Y/Z
#
# in order to automatize the index position identification for all the columns including mean or std
# three new vectors are created, in which the part of the string of interest is isolated 

# the vector below allows to identify feature names for the cases 1) and 2)
meanSt1 <- substrRight(names(final), 6) 
ident1 <- sapply(meanSt1, function(x) ifelse(x=="mean()"|x=="-std()"| x=="yMean)", ident1<-1, ident1 <- 0)) 

# the vector below allows to identify feature names for the cases 3)
meanSt2 <- substrRight(names(final), 8) # enlarge the letters selection from the string
meanSt2 <- substrRightAlt(meanSt2, 2) # remove the last two letters of the string, so that when we have the case 3) (e.i.name-mean()-X/Y/Z) the -X/Y/Z are removed
ident2 <- sapply(meanSt2, function(x) ifelse(x=="mean()"|x=="-std()", ident2 <-1, ident2 <- 0))

ident <- ident1+ident2 # the identified features indexs including mean or std data are included in a single file
selected <- which(as.logical(ident))
subsample <- final[, c(1,2,3,selected)]


#################################
# E) 5) new dataset with averages

(dim(subsample)[[2]]) # there are 72 columns including measurements for std and mean, and 3 extra columns for Subject, activity and train/test group

subsample$ident <- factor(paste(subsample$SubID, subsample$Activity)) # create a unique factor for each combination of Subjects id and activity
unique(subsample$ident) 
# 180 Levels: 1 LAYING 1 SITTING 1 STANDING 1 WALKING 1 WALKING-DOWNSTAIRS ... 30 WALKING-UPSTAIRS 
# identify the number of unique combinations between subjects and activities, there are 180 combinations

library(plyr)
library(dplyr)

# relabel features
result <- gsub("[[:punct:]]", "_", names(subsample)) # substitute the special symbols with _ in the column names
result1 <- gsub("__", "", result) # remove __ 
setnames(subsample, old=names(subsample), new=result1) # substitute previous column names with the clean ones

# process to obtain the data frame including means in subgroups
by_idSub <- group_by(subsample, ident) # create the subgroups
cols <- names(by_idSub)[-c(1,2,3,76)] # removes the column not including features
test <- sapply(cols, function(x) substitute(mean(x), list(x=as.name(x))))
final <- data.frame(do.call(summarise, c(list(.data=by_idSub), test)))

# export the final dataset
write.table(final, "~/data/R/coursera/getting_cleaning_data/project/final.txt", row.name=FALSE)

# alternative pipeline approach to obtain the new dataset
subsample %>% group_by(ident) %>% alt <- summarise_each(funs(mean))
