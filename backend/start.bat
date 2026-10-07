@echo off
set "SPRING_PROFILES_ACTIVE=prod"
set "MONGODB_URI=mongodb+srv://sanvitero2000_db_user:z0MH6hwBVJlPZO8j@mypethotel.ohz8ya5.mongodb.net/mypet?retryWrites=true&w=majority&appName=MyPetHotel"
java -jar target\backend-0.0.1-SNAPSHOT.jar
