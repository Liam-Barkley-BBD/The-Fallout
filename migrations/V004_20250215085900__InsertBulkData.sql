ALTER TABLE "BeanMissions" DROP COLUMN "ActualEnd";
ALTER TABLE "BeanMissions" RENAME COLUMN "PlannedStart" TO "StartDate";
ALTER TABLE "BeanMissions" RENAME COLUMN "PlannedEnd" TO "EndDate";

-- Add missing dates constraints for BeanMissions table
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_StartDateEndDate CHECK ("StartDate" < "EndDate");
ALTER TABLE "BeanMissions"
ADD CONSTRAINT CHK_BeanMissions_EndDate CHECK ("EndDate" <= CURRENT_DATE);

ALTER TABLE "Survivors"
DROP COLUMN "PasswordHash";

-- Disable foreign key checks temporarily to avoid constraint issues during bulk insert
SET session_replication_role = 'replica';

-- Truncate the table before inserting
TRUNCATE TABLE "Managers" RESTART IDENTITY CASCADE;

-- Insert Managers
INSERT INTO "Managers"("SurvivorID") VALUES
(5),
(10),
(43),
(55),
(63),
(76),
(91),
(106),
(121),
(136);


-- Insert Survivors
INSERT INTO "Survivors"("FirstName", "LastName", "BirthDate") VALUES
('Debra', 'Jenkins', '2014-12-27'),
('Mike', 'Smith', '1947-04-16'),
('Joseph', 'York', '1961-02-09'),
('Stacey', 'Carr', '1975-03-15'),
('John', 'Coleman', '1968-06-10'),
('Kimberly', 'Williams', '1954-08-14'),
('Joshua', 'Diaz', '2007-11-02'),
('Destiny', 'Rodriguez', '2007-03-14'),
('Benjamin', 'White', '1979-11-03'),
('Kenneth', 'Berry', '1968-01-29'),
('Carl', 'Allen', '1941-09-11'),
('William', 'Bradley', '1986-07-01'),
('Steven', 'Reid', '1999-08-08'),
('Robert', 'Jackson', '2013-10-17'),
('Jason', 'Coleman', '1948-12-20'),
('Keith', 'Scott', '2000-12-03'),
('Cory', 'Gonzalez', '2010-01-28'),
('Thomas', 'Holloway', '1945-09-03'),
('Patricia', 'Webster', '1950-03-20'),
('Eric', 'Browning', '1992-08-19'),
('Justin', 'King', '1995-10-06'),
('Michael', 'Ryan', '1962-04-05'),
('Jacqueline', 'Bowers', '1953-02-08'),
('Larry', 'Butler', '1957-12-28'),
('Nicholas', 'Underwood', '1942-11-25'),
('Rachel', 'Mcintyre', '1948-07-21'),
('Kristin', 'Parker', '1995-12-06'),
('Joseph', 'Graves', '1978-01-21'),
('Richard', 'Smith', '1940-12-02'),
('Rebecca', 'Pacheco', '1977-11-12'),
('Richard', 'Gardner', '2012-03-10'),
('Edward', 'Lopez', '1952-07-02'),
('Hannah', 'Collins', '1956-07-01'),
('Mariah', 'Brown', '1994-07-08'),
('Denise', 'Edwards', '2004-10-12'),
('Laura', 'Lynch', '1984-11-07'),
('Maurice', 'Ramirez', '1980-08-15'),
('Matthew', 'Davis', '1977-08-04'),
('Suzanne', 'Crawford', '1940-06-16'),
('Patrick', 'Ford', '1974-07-09'),
('Gregory', 'Hayes', '1977-06-09'),
('Christy', 'Morales', '1967-02-05'),
('Molly', 'Taylor', '1951-05-17'),
('Tiffany', 'Wells', '2000-12-24'),
('Nicholas', 'Jones', '1987-03-04'),
('Nicole', 'Villarreal', '2003-11-01'),
('Cynthia', 'Kelly', '1945-09-29'),
('Stephanie', 'Armstrong', '1996-09-27'),
('Shelley', 'Turner', '1973-07-31'),
('Jeremy', 'Johnson', '2002-09-02'),
('John', 'Smith', '1985-04-12'),
('Emily', 'Johnson', '1992-09-30'),
('Micheal', 'Brown', '1978-06-25'),
('Sarah', 'Davis', '2001-01-14'),
('Christopher', 'Wilson', '1965-11-22'),
('Amanda', 'Martinez', '1995-07-08'),
('Matthew', 'Anderson', '1980-02-19'),
('Jessica', 'Thomas', '2003-12-05'),
('Daniel', 'White', '1959-08-17'),
('Lauren', 'Harris', '1987-05-20'),
('David', 'Clark', '1999-10-11'),
('Ashley', 'Lewis', '1972-03-15'),
('Brian', 'Walker', '1968-06-29'),
('Megan', 'Hall', '1990-09-03'),
('Joshua', 'Allen', '2006-07-22'),
('Samantha', 'Young', '1975-12-30'),
('Andrew', 'King', '1983-04-07'),
('Rachel', 'Wright', '1962-05-25'),
('Kevin', 'Scott', '1998-08-14'),
('Nicole', 'Green', '1970-11-09'),
('Steven', 'Adams', '1981-02-23'),
('Victoria', 'Baker', '2009-06-18'),
('Ryan', 'Gonzalez', '1967-07-12'),
('Brittany', 'Nelson', '1989-10-21'),
('Justin', 'Carter', '2004-01-03'),
('Michelle', 'Mitchell', '1958-03-28'),
('Benjamin', 'Perez', '1979-12-14'),
('Olivia', 'Roberts', '1993-05-08'),
('Zachary', 'Turner', '1960-07-19'),
('Stephanie', 'Phillips', '2000-11-27'),
('Nathan', 'Campbell', '1986-09-10'),
('Abigail', 'Parker', '1973-02-01'),
('Brandon', 'Evans', '1997-06-04'),
('Alyssa', 'Edwards', '1966-04-15'),
('Tyler', 'Collins', '2007-08-09'),
('Rebecca', 'Stewart', '1982-10-30'),
('Ethan', 'Sanchez', '1957-05-14'),
('Madison', 'Morris', '1991-03-18'),
('Alexander', 'Rogers', '1963-12-22'),
('Hannah', 'Reed', '2005-07-02'),
('Jacob', 'Cook', '1976-09-25'),
('Isabella', 'Morgan', '1984-11-07'),
('Logan', 'Bell', '2008-04-29'),
('Sophia', 'Murphy', '1955-06-10'),
('William', 'Foster', '2002-02-20'),
('Chloe', 'Bailey', '1971-12-12'),
('James', 'Howard', '1996-08-05'),
('Ava', 'Cox', '1961-03-27'),
('Elijah', 'Ward', '1988-07-31'),
('Lily', 'Richardson', '1977-10-08'),
('Dylan', 'Brooks', '1994-06-14'),
('Ella', 'Watson', '1956-02-09'),
('Gabriel', 'Patterson', '1980-09-02'),
('Zoey', 'Gray', '2003-05-30'),
('Henry', 'Russell', '1964-04-12'),
('Natalie', 'Butler', '1995-08-26'),
('Mason', 'Simmons', '1974-12-05'),
('Emily', 'Foster', '2009-03-21'),
('Carter', 'James', '1987-07-17'),
('Scarlett', 'Bennett', '1969-01-10'),
('Jackson', 'Henderson', '1990-11-11'),
('Grace', 'Alexander', '1953-09-07'),
('Lucas', 'Bryant', '2001-06-29'),
('Layla', 'Torres', '1983-02-18'),
('Sebastian', 'Flores', '1978-05-09'),
('Harper', 'Rivera', '2006-10-24'),
('Julian', 'Cooper', '1965-07-05'),
('Addison', 'Perry', '1998-03-06'),
('Levi', 'Powell', '1959-11-30'),
('Stella', 'Long', '1982-09-01'),
('Hudson', 'Jenkins', '1970-06-14'),
('Penelope', 'Sanders', '2007-04-19'),
('Owen', 'Price', '1962-12-03'),
('Victoria', 'Barnes', '1986-08-11'),
('Samuel', 'Ross', '1950-01-27'),
('Camila', 'Ramirez', '2005-07-15'),
('Isaiah', 'Foster', '1992-05-22'),
('Lucy', 'Griffin', '1968-09-17'),
('Charles', 'Kim', '1979-10-13'),
('Eleanor', 'Ortiz', '1984-02-05'),
('Miles', 'Jenkins', '2008-06-09'),
('Brooklyn', 'Nguyen', '1957-07-20'),
('Harrison', 'Carter', '1999-12-23'),
('Savannah', 'Hayes', '1975-04-16'),
('Thomas', 'Wood', '1981-08-08'),
('Anna', 'Bell', '1966-01-31'),
('Caleb', 'Peterson', '2002-11-28'),
('Aurora', 'Sanders', '1973-03-25'),
('Wyatt', 'Richardson', '1995-09-12'),
('Madeline', 'Coleman', '2004-12-07'),
('Nathaniel', 'Hughes', '1960-10-05'),
('Caroline', 'Chapman', '1989-06-18'),
('Elias', 'Barker', '1972-02-14'),
('Hazel', 'Adams', '2003-08-21'),
('Nicholas', 'Hernandez', '1954-05-30'),
('Ruby', 'Morales', '2000-07-16'),
('Leo', 'Ward', '1985-12-02'),
('Violet', 'Russell', '1997-04-08'),
('Theodore', 'Hill', '1963-09-19'),
('Claire', 'Simmons', '2009-01-04');


-- Insert Shelters
INSERT INTO "Shelters"("PopulationCapacity", "SupplyVolume", "Latitude", "Longitude", "EstablishedDate", "DecommisionDate") VALUES
(1412, 902, 67.946451, -73.210151, '1997-03-20', '2024-08-28'),
(1571, 102, 3.61499, 86.800509, '2006-03-04', NULL),
(1621, 223, -75.460959, 60.82198, '1990-04-24', '2023-09-08'),
(1537, 791, -56.740327, -104.172759, '1995-06-12', NULL),
(1970, 805, 30.045778, -58.959951, '1994-08-04', '2023-05-12'),
(491, 777, 32.768733, 148.210753, '2002-12-22', '2022-05-28'),
(1167, 704, 61.435238, 160.461121, '2006-09-24', NULL),
(1363, 400, 77.349765, -50.9311, '2017-07-02', '2022-05-10'),
(552, 80, -19.455558, -56.048075, '2010-07-17', '2022-12-13'),
(1782, 703, -33.705646, -58.030101, '2004-04-03', NULL),
(1715, 675, -53.20426, -76.423855, '2011-06-15', '2021-06-14'),
(1365, 717, -26.07221, -108.553482, '1996-03-17', NULL),
(1662, 751, 11.621293, 17.407299, '1992-10-18', '2024-06-16'),
(1442, 297, -72.898712, 94.379481, '1998-05-17', '2021-02-17'),
(1301, 492, 40.765043, 148.493208, '1995-08-05', NULL),
(452, 526, 65.3845, 45.620892, '1999-12-12', '2023-10-29'),
(1642, 56, -28.853449, -34.335308, '2014-03-11', NULL),
(519, 137, -64.730099, 102.417062, '2008-11-18', '2024-12-04'),
(1940, 974, 80.43879, 83.671295, '1991-06-17', '2024-06-22'),
(1734, 663, -5.546364, -105.133966, '2002-11-10', NULL),
(1985, 727, 18.379157, 75.193217, '1996-08-15', '2024-05-19'),
(1622, 618, -35.360064, 86.863831, '2013-05-11', NULL),
(829, 685, -11.979463, 20.387909, '2002-10-26', '2023-05-31'),
(1027, 617, 30.732236, -44.899198, '2007-05-10', NULL),
(1117, 726, 5.870902, -153.920533, '1999-08-17', '2023-12-15'),
(1763, 70, -69.719042, -118.502138, '1992-12-09', '2025-11-18'),
(1305, 602, -23.828648, -120.939737, '2017-05-06', '2024-09-01'),
(1513, 914, -66.89354, 159.113679, '2000-11-05', '2021-07-22'),
(772, 844, -16.877594, 103.572787, '1997-03-30', '2025-03-22');


-- Insert ShelterSurvivors 
INSERT INTO "ShelterSurvivors"("SurvivorID", "ShelterID") VALUES
(1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2),
(11, 2), (12, 2), (13, 2), (14, 2), (15, 2), (16, 4), (17, 4), (18, 4), (19, 4), (20, 4),
(21, 4), (22, 4), (23, 4), (24, 4), (25, 4), (26, 4), (27, 4), (28, 4), (29, 4), (30, 4),
(31, 7), (32, 7), (33, 7), (34, 7), (35, 7), (36, 7), (37, 7), (38, 7), (39, 7), (40, 7),
(41, 7), (42, 7), (43, 7), (44, 7), (45, 7), (46, 10), (47, 10), (48, 10), (49, 10), (50, 10),
(51, 10), (52, 10), (53, 10), (54, 10), (55, 10), (56, 10), (57, 10), (58, 10), (59, 10), (60, 10),
(61, 12), (62, 12), (63, 12), (64, 12), (65, 12), (66, 12), (67, 12), (68, 12), (69, 12), (70, 12),
(71, 12), (72, 12), (73, 12), (74, 12), (75, 12), (76, 15), (77, 15), (78, 15), (79, 15), (80, 15),
(81, 15), (82, 15), (83, 15), (84, 15), (85, 15), (86, 15), (87, 15), (88, 15), (89, 15), (90, 15),
(91, 17), (92, 17), (93, 17), (94, 17), (95, 17), (96, 17), (97, 17), (98, 17), (99, 17), (100, 17),
(101, 17), (102, 17), (103, 17), (104, 17), (105, 17), (106, 20), (107, 20), (108, 20), (109, 20), (110, 20),
(111, 20), (112, 20), (113, 20), (114, 20), (115, 20), (116, 20), (117, 20), (118, 20), (119, 20), (120, 20),
(121, 22), (122, 22), (123, 22), (124, 22), (125, 22), (126, 22), (127, 22), (128, 22), (129, 22), (130, 22),
(131, 22), (132, 22), (133, 22), (134, 22), (135, 22), (136, 24), (137, 24), (138, 24), (139, 24), (140, 24),
(141, 24), (142, 24), (143, 24), (144, 24), (145, 24), (146, 24), (147, 24), (148, 24), (149, 24), (150, 24);


-- Insert BeanSupplies
INSERT INTO "BeanSupplies"("ShelterID", "CannedBeanID", "ConsumedDate") VALUES
(24, 1, '2024-01-05'), (24, 3, NULL), (24, 5, NULL), 
(22, 7, NULL), (22, 2, '2024-02-10'), (22, 9, NULL),
(20, 6, '2024-02-20'), (20, 4, NULL), (20, 10, NULL),
(17, 8, NULL), (17, 1, '2024-03-05'), (17, 3, NULL),
(15, 5, '2024-03-10'), (15, 7, NULL), (15, 2, NULL),
(12, 10, '2024-03-20'), (12, 6, NULL), (12, 8, '2024-03-25'),
(10, 7, '2024-04-01'), (10, 4, NULL), (10, 9, NULL),
(7, 1, NULL), (7, 5, NULL), (7, 3, NULL),
(4, 2, '2024-05-02'), (4, 10, NULL), (4, 3, NULL),
(2, 3, NULL), (2, 9, '2024-05-10'), (2, 4, NULL);


-- Insert CannedBeans
INSERT INTO "CannedBeans"("BeanType", "Grams") VALUES
('Chickpeas', 400), 
('Red Beans', 410), 
('Kidney Beans', 400),
('Cannellini beans', 400),
('Great Northern Beans', 400),
('Navy Beans', 410),
('Pinto Beans', 410),
('Black Beans', 410),
('Borlotti Beans', 400),
('Adzuki Beans', 250),
('Lima Beans', 400),
('Black Eyed Peas', 400),
('Magic Beans', 50);


-- Insert Bean Requests
INSERT INTO "BeanRequests"("SurvivorID", "Approved", "RequestTime") VALUES
(12, TRUE, '2025-01-10'),
(45, FALSE, '2025-01-11'),
(78, TRUE, '2025-01-12'),
(33, TRUE, '2025-01-02'),
(54, FALSE, '2025-01-01'),
(1, TRUE, '2025-01-01'),
(5, FALSE, '2025-01-02'),
(17, TRUE, '2025-01-01'),
(131, TRUE, '2024-12-24'),
(99, TRUE, '2025-01-09'),
(10, TRUE, '2025-01-03');


-- Insert Bean Request Items
INSERT INTO "BeanRequestItem"("CannedBeanID", "NumberOfCans", "BeanRequestID") VALUES
(3, 4, 1),
(1, 5, 2),
(7, 3, 3),
(9, 1, 4),
(6, 6, 5),
(5, 3, 6),
(7, 2, 7),
(11, 2, 8),
(9, 3, 9),
(8, 1, 10),
(4, 5, 11);


-- Insert Bean Missions
INSERT INTO "BeanMissions"("ShelterID", "StartDate", "EndDate") VALUES
(24, '2024-01-15', '2024-02-15'),
(22, '2024-02-10', '2024-03-10'),
(20, '2024-04-01', '2024-04-30'),
(17, '2024-05-05', '2024-06-05'),
(15, '2024-07-12', '2024-08-12'),
(12, '2024-09-01', '2024-10-01'),
(10, '2024-10-10', '2024-11-10'),
(7, '2024-11-20', '2024-12-20'),
(4, '2025-01-05', '2025-01-09'),
(2, '2025-02-10', '2025-02-14');

-- Insert Mission Yield Items
INSERT INTO "MissionYieldItems"("CannedBeanID", "NumberOfCans", "BeanMissionID") VALUES
(1, 120, 1),
(3, 90, 1),
(7, 110, 1),
(2, 150, 2),
(4, 80, 2),
(6, 100, 2),
(1, 130, 3),
(5, 70, 3),
(8, 90, 3),
(2, 200, 4),
(9, 85, 4),
(3, 140, 4),
(6, 120, 5),
(10, 95, 5),
(7, 160, 5);


-- Re-enable foreign key constraints
SET session_replication_role = 'origin';

COMMIT;
