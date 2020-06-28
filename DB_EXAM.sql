CREATE DATABASE TripService
USE TripService
--1.
CREATE TABLE Cities 
(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	[Name] NVARCHAR(20) NOT NULL,
	CountryCode VARCHAR(2) NOT NULL
)
CREATE TABLE Hotels
(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	[Name] NVARCHAR(30) NOT NULL,
	CityId INT NOT NULL,
	EmployeeCount INT NOT NULL,
	BaseRate DECIMAL(10,2),
	CONSTRAINT FK_Hotels_Cities
	FOREIGN KEY (CityId)
	REFERENCES Cities(Id)
)
CREATE TABLE Rooms
(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	Price DECIMAL (15,2) NOT NULL,
	[Type] NVARCHAR(20) NOT NULL,
	Beds INT NOT NULL,
	HotelId INT,
	CONSTRAINT FK_Rooms_Hotels
	FOREIGN KEY (HotelId)
	REFERENCES Hotels(Id)
)
CREATE TABLE Trips 
(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	RoomId INT NOT NULL,
	BookDate DATE NOT NULL,
	ArrivalDate DATE NOT NULL,
	ReturnDate DATE NOT NULL,
	CancelDate DATE,

	CONSTRAINT FK_Trips_Rooms
	FOREIGN KEY (RoomId)
	REFERENCES Rooms(Id),

	CONSTRAINT CK_Date_Check_1
	CHECK (BookDate < ArrivalDate),

	CONSTRAINT CK_Date_Check_2
	CHECK (ArrivalDate < ReturnDate)
)
CREATE TABLE Accounts
(
	Id INT PRIMARY KEY IDENTITY NOT NULL,
	FirstName NVARCHAR(50) NOT NULL, 
	MiddleName NVARCHAR(20),
	LastName NVARCHAR(50) NOT NULL,
	CityId INT NOT NULL,
	BirthDate DATE NOT NULL,
	Email VARCHAR(100) UNIQUE NOT NULL,
	CONSTRAINT FK_Accounts_Cities
	FOREIGN KEY (CityId)
	REFERENCES Cities(Id)
)
CREATE TABLE AccountsTrips 
(
	AccountId INT NOT NULL,
	TripId INT NOT NULL,
	Luggage INT NOT NULL CHECK (Luggage>=0),
	CONSTRAINT  PK_AccountsTrips
	PRIMARY KEY (AccountId, TripId),

	CONSTRAINT FK_AccountsTrips_Accounts
	FOREIGN KEY (AccountId)
	REFERENCES Accounts(Id),

	CONSTRAINT FK_AccountsTrips_Trips
	FOREIGN KEY (TripId)
	REFERENCES Trips(Id)

)
use master
drop database TripService
--2
USE TripService
INSERT INTO Accounts (FirstName,MiddleName,LastName,CityId,BirthDate,Email) VALUES 
('John','Smith','Smith',34,'1975-07-21','j_smith@gmail.com'),
('Gosho',NULL,'Petrov',11,'1978-05-16','g_petrov@gmail.com'),
('Ivan','Petrovich','Pavlov',59,'1849-09-26','i_pavlov@softuni.bg'),
('Friedrich','Wilhelm','Nietzsche',2,'1844-10-15','f_nietzsche@softuni.bg')

INSERT INTO Trips (RoomId,BookDate,ArrivalDate,ReturnDate,CancelDate) VALUES
(101,'2015-04-12','2015-04-14','2015-04-20','2015-02-02'),
(102,'2015-07-07','2015-07-15','2015-07-22','2015-04-29'),
(103,'2013-07-17','2013-07-23','2013-07-24',NULL),
(104,'2012-03-17','2012-03-31','2012-04-01','2012-01-10'),
(109,'2017-08-07','2017-08-28','2017-08-29',NULL)
--3.
UPDATE Rooms
SET Price *= 1.14
WHERE HotelId=5 OR HotelId=7 OR HotelId=9
--4.
DELETE FROM AccountsTrips
WHERE AccountId=47
--5.
SELECT FirstName, LastName, FORMAT (BirthDate, 'MM-dd-yyyy') AS [BirthDate],Cities.Name AS [Hometown],Email 
FROM Accounts
JOIN Cities ON Accounts.CityId=Cities.Id
WHERE Email LIKE 'e%'
ORDER BY Cities.Name
--6.
SELECT Cities.[Name] AS [City], COUNT(Hotels.Id) AS [Hotels]
FROM Cities
JOIN Hotels ON Hotels.CityId = Cities.Id
GROUP BY Cities.[Name]
ORDER BY [Hotels] DESC, Cities.[Name]
--7.
SELECT a.Id AS [AccountId],
		a.FirstName + ' ' + a.LastName AS [FullName],
		MAX(DATEDIFF(DAY, t.ArrivalDate, t.ReturnDate)) AS [LongestTrip],
		MIN(DATEDIFF(DAY, t.ArrivalDate, t.ReturnDate)) AS [ShortestTrip]
FROM Accounts AS a
JOIN AccountsTrips AS act ON act.AccountId = a.Id
JOIN Trips AS t ON t.Id = act.TripId
WHERE a.MiddleName IS NULL AND t.CancelDate IS NULL
GROUP BY a.Id, a.FirstName, a.LastName
ORDER BY [LongestTrip] DESC, [ShortestTrip]
--8.
SELECT TOP 10 
c.Id, c.[Name] AS [City], c.CountryCode AS [Country], COUNT(a.Id) AS [Accounts]
FROM Cities AS c
JOIN Accounts AS a ON a.CityId=c.Id
GROUP BY c.Id, c.[Name], c.CountryCode
ORDER BY [Accounts] DESC
--9.
SELECT a.Id,
	a.Email,
	c.[Name],
	COUNT(t.Id) AS [Trips]
FROM Accounts AS a
INNER JOIN AccountsTrips AS act ON act.AccountId = a.Id
INNER JOIN Trips AS t ON t.Id = act.TripId
INNER JOIN Rooms AS r ON R.Id = t.RoomId
INNER JOIN Hotels AS h ON H.Id = R.HotelId
INNER JOIN Cities AS c ON c.Id = H.CityId
WHERE a.CityId = h.CityId
GROUP BY a.Id, a.Email, c.[Name]
ORDER BY [Trips] DESC, a.Id
--10.
SELECT t.Id AS [Trip ID],
	CONCAT_WS(' ',a.FirstName, a.MiddleName, a.LastName) AS [Full Name],
	c.[Name] AS [From],
	h.[Name] AS [To],
	CASE
		WHEN t.CancelDate IS NOT NULL THEN 'Canceled'
		ELSE CONCAT_WS(' ',DATEDIFF(DAY,t.ArrivalDate,t.ReturnDate),'Days')
		END
		AS Duration
FROM Accounts AS a
JOIN Cities AS c ON c.Id = a.CityId
JOIN Hotels AS h ON h.CityId = c.Id
JOIN AccountsTrips AS act ON act.AccountId = a.Id
JOIN Trips AS t ON t.Id = act.TripId
ORDER BY [Full Name], t.Id

SELECT c.Name FROM Hotels AS h
JOIN Cities AS c ON c.Id = h.CityId
JOIN Accounts AS a ON a.CityId = c.Id
--11.

CREATE FUNCTION udf_GetAvailableRoom (@HotelId INT, @Date DATE, @People INT)
RETURNS VARCHAR (100)
AS
BEGIN
	DECLARE @arrivalDate DATE = 
						(SELECT TOP 1 ArrivalDate FROM Trips AS t
							JOIN Rooms AS r ON r.Id = t.RoomId
							JOIN Hotels AS h ON h.Id = r.HotelId
							WHERE h.Id = @HotelId)
	DECLARE @returnDate DATE = 
						(SELECT TOP 1 ReturnDate FROM Trips AS t
							JOIN Rooms AS r ON r.Id = t.RoomId
							JOIN Hotels AS h ON h.Id = r.HotelId
							WHERE h.Id = @HotelId)
	DECLARE @cancelDate DATE = 
						(SELECT TOP 1CancelDate FROM Trips AS t
							JOIN Rooms AS r ON r.Id = t.RoomId
							JOIN Hotels AS h ON h.Id = r.HotelId
							WHERE h.Id = @HotelId)		
							
	IF ((@Date BETWEEN @arrivalDate AND @returnDate) AND @cancelDate IS NULL)
	BEGIN
		RETURN 'No rooms available'
	END

	DECLARE @roomCheck INT = 
						(SELECT h.Id FROM Hotels AS h
							JOIN Rooms AS r ON r.HotelId = h.Id
							WHERE @HotelId = h.Id)
	DECLARE @bedCount INT =
						(SELECT r.Beds FROM Rooms AS r
							JOIN Hotels AS h ON h.Id = r.HotelId
							WHERE @HotelId = h.Id)
	DECLARE @roomId INT = 
						(SELECT r.Id FROM Rooms AS r
							JOIN Hotels AS h ON h.Id = r.HotelId
							WHERE @HotelId = h.Id)
	DECLARE @roomType NVARCHAR(20) =
						(SELECT r.[Type] FROM Rooms AS r
							JOIN Hotels AS h ON h.Id = r.HotelId
							WHERE @HotelId = h.Id)

	DECLARE @hotelBaseRate DECIMAL (10,2) = 
						(SELECT BaseRate FROM Hotels
							WHERE Hotels.Id = @HotelId)
	DECLARE @roomPrice DECIMAL (15,2) =
						(SELECT Price FROM Rooms
							JOIN Hotels ON Hotels.Id = Rooms.HotelId
							WHERE Hotels.Id = @HotelId)
	DECLARE @totalPriceOfRoom DECIMAL (15,2) = (@hotelBaseRate + @roomPrice) * @People
	
	IF(@roomCheck = @HotelId AND @bedCount >= @People)
	BEGIN
	DECLARE @result VARCHAR(100) = 
	CONCAT('Room',' ',@roomId,': ',@roomType, ' (',@bedCount,' beds)',' - $',@totalPriceOfRoom)
	END
	RETURN @result
END
SELECT dbo.udf_GetAvailableRoom(112, '2011-12-17', 2)
SELECT dbo.udf_GetAvailableRoom(94, '2015-07-26', 3)
DROP FUNCTION udf_GetAvailableRoom

CREATE PROC usp_SwitchRoom(@TripId INT, @TargetRoomId INT)
AS
	DECLARE @bedCheck INT = 
					(SELECT r.Beds FROM Trips AS t
						JOIN Rooms AS r ON r.Id = t.RoomId
						JOIN Hotels AS h ON h.Id = r.HotelId
						WHERE @TripId = t.Id)
	DECLARE @peopleCount INT =
					(SELECT COUNT(a.Id) FROM Trips AS t
						JOIN AccountsTrips AS act ON act.TripId = t.Id
						JOIN Accounts AS a ON a.Id = act.AccountId
						WHERE @TripId = t.Id)
	DECLARE @hotelId INT = 
					(SELECT h.Id FROM Hotels AS h
						JOIN Rooms AS r ON r.HotelId = h.Id
						JOIN Trips AS t ON t.RoomId = r.Id
						WHERE @TripId = t.Id)
	DECLARE @roomId INT =
					(SELECT h.Id FROM Hotels AS h
						JOIN Rooms AS r ON r.HotelId = h.Id
						JOIN Trips AS t ON t.RoomId = r.Id
						WHERE @TargetRoomId = r.Id)
	IF (@bedCheck < @peopleCount)
	RETURN 'Not enough beds in target room!'
	ELSE IF (@hotelId != @roomId)
	RETURN 'Target room is in another hotel!'
	ELSE 
		BEGIN
		UPDATE Trips
		SET RoomId = @TargetRoomId
		END
	
	EXEC usp_SwitchRoom 10, 7
	EXEC usp_SwitchRoom 10, 8
	EXEC usp_SwitchRoom 10, 11
SELECT RoomId FROM Trips WHERE Id = 10
