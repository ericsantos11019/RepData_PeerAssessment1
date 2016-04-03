packages <- c("data.table", "ggplot2", "scales", "stringr")
sapply(packages, library, character.only = TRUE, warn.conflicts = FALSE, 
       quietly = TRUE)

# Ensures we are in the right working directory (the folder where the R script is).
previousWD <- getwd()
newWD <- getSrcDirectory(function(x) {x})
setwd(newWD)
#---------------------------------------------------------------------------------------------------
# Loading and preprocessing the data
fileName <- "activity.csv"
zipFIlename <- "activity.zip"
dataFile <- unzip(zipFIlename)
data <- fread(fileName)
unlink(dataFile)
#---------------------------------------------------------------------------------------------------
# What is mean total number of steps taken per day?
# 1) Calculate the total number of steps taken per day
stepsPerDay <- data[, .(total = sum(steps, na.rm = T)), by = .(date)]

# 2) Make a histogram of the total number of steps taken each day
# g <- ggplot(stepsPerDay, aes(1:nrow(stepsPerDay), total)) + 
#   geom_bar(fill = "#5588BB", color = "#336699", size = 1, stat = "identity") + 
#   labs(x = "Day", y = "Steps Taken", title = "Histogram for Steps Taken per Day")

g <- ggplot(stepsPerDay, aes(total)) + 
  geom_histogram(fill = "#5588BB", color = "#336699", size = 1, binwidth = 1000) + 
  labs(x = "Steps Taken per Day", y = "Count", title = "Histogram for Steps Taken per Day") + 
  scale_x_continuous(breaks = seq(0, 22000, 2000))
print(g)

# 3) Calculate and report the mean and median of the total number of steps taken per day
meanMedian <- stepsPerDay[, .(mean = mean(total), median = median(total))]
#---------------------------------------------------------------------------------------------------
# What is the average daily activity pattern?
avgFiveMinuteInt <- data[, .(mean = mean(steps, na.rm = T), time = str_pad(interval, 4, pad = "0")), 
                         by = .(interval)]
timeVector <- strptime(avgFiveMinuteInt$time, "%H%M")

# 1) Make a time series plot f the 5-minute interval (x-axis) and the average number of steps taken,
# averaged across all days (y-axis)
g <- ggplot(avgFiveMinuteInt, aes(timeVector, mean)) + 
  geom_line(size = 1.2) + 
  labs(x = "Time", y = "Average Steps Taken", 
       title = "Average Steps Taken per 5-minute Intervals") + 
  scale_x_datetime(labels=date_format("%H:%M", tz = Sys.timezone()))
print(g)

# 2) Which 5-minute interval, on average across all the days in the dataset, contains the maximum 
# number of steps?
maxSteps <- avgFiveMinuteInt[which.max(mean)]
#---------------------------------------------------------------------------------------------------
# Imputing missing values

# 1) Calculate and report the total number of missing values in the dataset (i.e. the total number
# of rows with NAs)
numMissing <- sum(is.na(data$steps))

# 2) Devise a strategy for filling in all of the missing values in the dataset.
# 3) Create a new dataset that is equal to the original dataset but with the missing data filled in.
setkey(data, interval)
setkey(avgFiveMinuteInt, interval)
filledData <- data[avgFiveMinuteInt]
filledData$steps <- as.double(filledData$steps)
filledData[is.na(steps), steps := mean]
filledData <- filledData[, .(steps, date, interval)]
setkey(filledData, date)

# 4) Make a histogram of the total number of steps taken each day and Calculate and report the mean 
# and median total number of steps taken per day.
stepsPerDay2 <- filledData[, .(total = sum(steps, na.rm = T)), by = .(date)]

g <- ggplot(stepsPerDay2, aes(total)) + 
  geom_histogram(fill = "#5588BB", color = "#336699", size = 1, binwidth = 1000) + 
  labs(x = "Steps Taken per Day", y = "Count", title = "Histogram for Steps Taken per Day") + 
  scale_x_continuous(breaks = seq(0, 22000, 2000))
print(g)

meanMedian2 <- stepsPerDay2[, .(mean = mean(total), median = median(total))]
#---------------------------------------------------------------------------------------------------
# Are there differences in activity patterns between weekdays and weekends?
Sys.setlocale(locale = "en_US")
filledData[, c("day_of_week", "weekday") := list(weekdays(strptime(date, "%Y-%m-%d")), "Weekday")]
filledData[(day_of_week == "Saturday") | (day_of_week == "Sunday"), weekday := "Weekend"]

avgFiveMinuteInt2 <- filledData[, .(mean = mean(steps, na.rm = T), time = str_pad(interval, 4, pad = "0")), 
                         by = .(interval, weekday)]
timeVector2 <- strptime(avgFiveMinuteInt2$time, "%H%M")

g <- ggplot(avgFiveMinuteInt2, aes(timeVector2, mean)) + 
  geom_line(size = 1.2) + 
  labs(x = "Time", y = "Average Steps Taken", 
       title = "Average Steps Taken per 5-minute Intervals") +
  facet_grid(weekday ~ .) + 
  scale_x_datetime(labels=date_format("%H:%M", tz = Sys.timezone()))
print(g)

setwd(previousWD)
