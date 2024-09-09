install.packages("DBI")
install.packages("RMySQL")
install.packages("readr")
install.packages("dplyr")

library(DBI)
library(RMySQL)
library(readr)
library(tidyr)
library(dplyr)

#Connect to DB
con <- dbConnect(RMySQL::MySQL(), 
                 dbname = 'movies_db',
                 host = 'data607.cx2ygaw0ijp1.us-east-2.rds.amazonaws.com', 
                 port = 3306, 
                 user = '', 
                 password = '')

#Drop tables if they exist
dbExecute(con, "DROP TABLE IF EXISTS movie_ratings;")
dbExecute(con, "DROP TABLE IF EXISTS friends;")

#Create the 'friends' table
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS friends (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
  );
")

#Create the 'movie_ratings' table
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS movie_ratings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie VARCHAR(100),
    friend_id INT,
    rating INT,
    FOREIGN KEY (friend_id) REFERENCES friends(id)
  );
")

#Load the CSV file from URL
url <- "https://raw.githubusercontent.com/Amish22/DS607/main/movies_data.csv"
movie_data <- read_csv(url)

long_movie_data <- movie_data %>%
  pivot_longer(cols = starts_with("Friend"), 
               names_to = "friend_name", 
               values_to = "rating", 
               values_drop_na = FALSE) # Keep NA ratings

friends_data <- data.frame(name = unique(long_movie_data$friend_name))

dbWriteTable(con, "friends", friends_data, append = TRUE, row.names = FALSE)

friend_ids <- dbGetQuery(con, "SELECT id, name FROM friends")

long_movie_data <- merge(long_movie_data, friend_ids, by.x = "friend_name", by.y = "name")

insert_data <- long_movie_data %>%
  select(Movie, id, rating) %>%
  rename(friend_id = id)

dbWriteTable(con, "movie_ratings", insert_data, append = TRUE, row.names = FALSE)

#Checking the data insertion
result <- dbGetQuery(con, "SELECT * FROM movie_ratings;")
print(result)

# Step 13: Disconnect from the database
dbDisconnect(con)

