--Code for a computed column to track total number of orders for each customer
CREATE FUNCTION fn_totalorders(@CustomerID INT)
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = (SELECT COUNT(OrderID) FROM ORDERS
                   WHERE CustomerID=@CustomerID)
RETURN @Ret
END

ALTER TABLE ORDERS
ADD fn_totalorders
AS (dbo.fn_totalorders(CustomerID))


--Code to CREATE a stored procedure that inserts a new row into STORE
CREATE PROCEDURE usp_newstore
@StoreName varchar(100),
@LocationName varchar(100),
@PhoneNumber varchar(20),
@StoreTypeName varchar(100)
AS
DECLARE @LocationID INT = (SELECT LocationID FROM LOCATION WHERE LocationName=@LocationName)
DECLARE @StoreTypeName INT = (SELECT StoreTypeNameID FROM STORE_TYPE WHERE StoreTypeName=@StoreTypeName)
BEGIN TRAN t1
INSERT INTO STORE(StoreName, LocationID, PhoneNumber, StoreTypeID)
VALUES (@StoreName, @LocationID, @PhoneNumber, @StoreTypeID)
GO

IF @@ERROR <> 0
   ROLLBACK TRAN t1
ELSE  
   COMMIT TRAN t1

EXEC usp_newstore
@StoreName 'Patagonia',
@LocationName 'B3',
@PhoneNumber '(260)-555-5555',
@StoreTypeName 'Clothing'


--Code to CREATE a stored procedure that inserts a new row into PRODUCT as well as a --new PRODUCT_TYPE all in a single explicit transaction
CREATE PROCEDURE usp_newproduct
@ProductName varchar(100),
@ProductTypeName varchar(100),
@ProductTypeDescr varchar(100),
@StoreName varchar(100),
@ProductDescr varchar(100),
@Cost varchar(10)
AS
INSERT INTO PRODUCT_TYPE(ProductTypeName, ProductTypeDescr)
VALUES (@ProductTypeName, @ProductTypeDescr)
DECLARE @ProductTypeID INT = SCOPE_IDENTITY()
BEGIN TRAN t1
INSERT INTO PRODUCT(ProductTypeID, ProductDescr, Cost, ProductName)
VALUES (@ProductTypeID, @ProductDescr, @Cost, @ProductName)
GO

IF @@ERROR <> 0
   ROLLBACK TRAN t1
ELSE   
   COMMIT TRAN t1
GO

EXEC usp_newproduct
@ProductName 'Nano Puff Jacket'
@ProductTypeName 'Clothing',
@ProductTypeDescr 'Jacket',
@StoreName varchar 'Patagonia',
@ProductDescr 'Waterproof',
@Cost varchar '$85'


--Query to determine which customers have placed more than 3 orders from the store --"Patagonia" located at Northgate Mall and "Nature USA" as manufacturer with rating --of 4 or higher
CREATE VIEW vw_patagoniaNorthgate
AS
SELECT C.CustomerID, C.CustomerFname, C.CustomerLname FROM CUSTOMER C
   JOIN ORDERS O ON O.CustomerID=C.CustomerID
   JOIN LINE_ITEM LI ON LI.OrderID=O.OrderID
   JOIN PRODUCT P ON P.ProductID=LI.ProductID
   JOIN REVIEW R ON R.ProductID=P.ProductID
   JOIN RATING RT ON RT.RatingID=R.RatingID
   JOIN MANUFACTURER_PRODUCT MP ON MP.ProductID=P.ProductID
   JOIN MANUFACTURER M ON M.ManufacturerID=MP.ManufacturerID
   JOIN STORE_PRODUCT SP ON SP.ProductID=P.ProductID
   JOIN STORE S ON S.StoreID=SP.StoreID
   JOIN MALL_STORE MS ON MS.StoreID=S.StoreID
   JOIN MALL ML ON ML.MallID=MS.MallID
WHERE S.StoreName='Patagonia'
AND ML.MallName='Northgate Mall'
AND M.ManufacturerName='Nature USA'
AND RT.Rating >= 4
GROUP BY C.CustomerID, C.CustomerFname, C.CustomerLname
HAVING COUNT(*) >= 3


--Code to enforce the business rule that customers younger than 21 cannot have a order with product type of alcohol
CREATE FUNCTION fn_noAlcoholForMinors()
RETURNS INT
AS BEGIN
DECLARE @Ret INT = 0
IF EXISTS (SELECT * FROM CUSTOMER C
           JOIN ORDERS O ON O.CustomerID=C.CustomerID
           JOIN LINE_ITEM LI ON LI.OrderID=O.OrderID
           JOIN PRODUCT P ON P.ProductID=LI.ProductID
           JOIN PRODUCT_TYPE PT ON PT.ProductTypeID=P.ProductTypeID
           WHERE C.DateOfBirth > (SELECT GetDate() - (365.25 * 21))
           AND PT.ProductTypeName='Alcohol')
   SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE ORDERS
ADD CONSTRAINT CK_noAlcoholForMinors
CHECK (dbo.fn_noAlcoholForMinors() = 0)
GO




-- Code to CREATE a stored procedure that inserts a new row into the ORDER table in a single explicit transaction
CREATE PROCEDURE usp_newOrder
@OrderTypeName varchar(30),
@CustomerFname varchar(20),
@CustomerLname varchar(20),
@Email varchar(40)

AS
DECLARE @CustomerID INT = (SELECT CustomerID
                           FROM CUSTOMER
                       WHERE CustomerFname = @CustomerFname AND
                           CustomerLname = @CustomerLname AND
                           Email = @Email)
DECLARE @OrderTypeID INT = (SELECT OrderTypeID FROM ORDER_TYPE WHERE OrderTypeName = @OrderTypeName)
BEGIN TRAN T1
INSERT INTO ORDERS(OrderTypeID, CustomerID, OrderDate)
VALUES(@OrderTypeID, @CustomerID, GETDATE())

IF @@ERROR <> 0
   ROLLBACK TRAN T1
ELSE
   COMMIT TRAN T1
GO


-- Code to CREATE a stored procedure that inserts a new row into the REVIEW table in a single explicit transaction
CREATE PROCEDURE usp_newReview
@ReviewName varchar(100),
@ReviewDescr varchar(100),
@ProductName varchar(100),
@ProductTypeName varchar(100),
@ShortName varchar(100),
@Description varchar(100)

AS
DECLARE @ProductTypeID INT = (SELECT ProductTypeID FROM PRODUCT_TYPE WHERE ProductTypeName = @ProductTypeName)
DECLARE @ProductID INT = (SELECT ProductID FROM PRODUCT WHERE ProductName = @ProductName AND ProductTypeID = @ProductTypeID)
DECLARE @RatingID INT = (SELECT RatingID FROM RATING WHERE ShortName = @ShortName AND [Descr] = @Description)

BEGIN TRAN T1
INSERT INTO REVIEW(ReviewName, ReviewDescr, ProductID, RatingID)
VALUES(@ReviewName, @ReviewDescr, @ProductID, @RatingID)

IF @@ERROR <> 0
   ROLLBACK TRAN T1
ELSE
   COMMIT TRAN T1
GO


-- Code to CREATE a business rule that prevents sale of products manufactured by 'Gibberish Manufacturing', if they have more
-- than 10 products with a rating below 3
CREATE FUNCTION fn_limitManufacturerProducts()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(
   SELECT COUNT(*)
   FROM PRODUCT P
       JOIN REVIEW R ON P.ProductID = R.ProductID
       JOIN RATING RT ON R.RatingID = RT.RatingID
       JOIN MANUFACTURER_PRODUCT MP ON P.ProductID = MP.ProductID
       JOIN MANUFACTURER M ON MP.ManufacturerID = M.ManufacturerID
   WHERE ManufacturerName = 'Gibberish Manufacturing' AND
   RT.Rating < 3
   GROUP BY P.ProductID
   HAVING COUNT(*) > 10)
SET @RET = 1
RETURN @RET
END

GO

ALTER TABLE PRODUCT
ADD CONSTRAINT CK_limitGibberishProduct
CHECK (dbo.fn_limitManufacturerProducts() = 0)
GO


CREATE FUNCTION fn_NumberOfStoresInMall(@MallID INT)
RETURNS INT
AS
BEGIN
DECLARE @RET INT = (SELECT COUNT(*)
                   FROM MALL M
                   JOIN MALL_STORE MS ON M.MallID = MS.MallID
                   JOIN STORE S ON MS.StoreID = S.StoreID
                   WHERE M.MallID = @MallID)
RETURN @RET
END
GO

ALTER TABLE MALL
ADD NumStores
AS (dbo.fn_NumberOfStoresInMall(MallID))
GO

-- Code that returns the number of customers who have bought clothing products from the Macy's at Alderwood Mall

CREATE VIEW vw_clothingProductsAtAlderwoodMacys
AS
SELECT COUNT(*) AS NumCustomers
FROM CUSTOMER C
JOIN ORDERS O ON C.CustomerID = O.CustomerID
JOIN LINE_ITEM LI ON O.OrderID = LI.OrderID
JOIN PRODUCT P ON LI.ProductID = P.ProductID
JOIN PRODUCT_TYPE PT ON P.ProductTypeID = PT.ProductTypeID
JOIN STORE_PRODUCT SP ON P.ProductID = SP.ProductID
JOIN STORE S ON SP.StoreID = S.StoreID
JOIN MALL_STORE MS ON S.StoreID = MS.StoreID
JOIN MALL M ON MS.MallID = M.MallID
WHERE MallName = 'Alderwood' AND
StoreName = 'Macy''s' AND
ProductTypeName = 'Clothing'
GROUP BY C.CustomerID


-- Code to CREATE a stored procedure that inserts a new row into MALL as well as a new
MALL_LOCATION all in a single explicit transaction
CREATE PROCEDURE uspNewMallLocation
@Address varchar(100),
@MallLocationDescr varchar(100),
@MallName varchar(100),
@MallDescr varchar(100)
AS 
BEGIN TRAN T1
INSERT INTO MALL_LOCATION(MallLocationDescr, Address)
VALUES(@MallLocationDescr, @Address)
DECLARE @MallLocationID INT = SCOPE_IDENTITY()
INSERT INTO MALL(MallName, MallDescr, MallLocationID)
VALUES(@MallName, @MallDescr, @MallLocationID)
IF @@ERROR <> 0
ROLLBACK TRAN T1
ELSE 
COMMIT TRAN T1
GO


-- Code to CREATE a stored procedure that inserts a new row into SCHEDULE
CREATE PROCEDURE uspNewSchedule
@DayName varchar(100),
@StoreName varchar(100),
@OpenTime time(7),
@CloseTime time(7)
AS 
DECLARE @DayID INT = (SELECT DayID FROM DAY WHERE DayName = @DayName)
DECLARE @StoreID INT = (SELECT StoreID FROM STORE WHERE StoreName = @StoreName) 
BEGIN TRAN T1
INSERT INTO SCHEDULE(StoreID, DayID, Open, Close)
VALUES(@StoreID, @DayID, @OpenTime, @CloseTime)
IF @@ERROR <> 0
ROLLBACK TRAN T1
ELSE 
COMMIT TRAN T1
GO


-- Code to add a business rule where ratings cant be more than 5 and less than 0
CREATE FUNCTION fn_NoRatingMoreThan5OrLessThan0()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT * FROM REVIEW R
		JOIN RATING RA ON RA.RatingID = R.RatingID
		WHERE RA.Rating > 5 OR RA.Rating < 0)
		SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE RATING
ADD CONSTRAINT RatingLimit
CHECK (dbo.fn_NoRatingMoreThan5OrLessThan0()=0)


-- Code to add a computed column that calculates the percentage of ratings a product got
CREATE FUNCTION fn_RatingPercentage(@ProductID INT)
RETURNS INT
AS
BEGIN
DECLARE @RET INT = (SELECT (SELECT SUM(RA.Rating)/(COUNT(RA.Rating) * 5))*100 FROM PRODUCT P 
JOIN REVIEW R ON R.ProductID = P.ProductID
JOIN RATING RA ON RA.RatingID = R.RatingID
WHERE P.ProductID = @ProductID)
RETURN @RET
END
GO

ALTER TABLE Product
ADD ProductRating
AS (dbo.fn_RatingPercentage(ProductID))
GO


-- Code that counts the number of customers who bought shoes from the Northgate Mall on a Saturday

CREATE VIEW vw_NumberOfCustomersBoughtShoes
AS
SELECT COUNT(*) AS NumCustomers FROM CUSTOMER C
JOIN ORDERS O ON C.CustomerID = O.CustomerID
JOIN LINE_ITEM LI ON O.OrderID = LI.OrderID
JOIN PRODUCT P ON LI.ProductID = P.ProductID
JOIN STORE_PRODUCT SP ON P.ProductID = SP.ProductID
JOIN STORE S ON SP.StoreID = S.StoreID
JOIN SCHEDULE SC ON SC.StoreID = S.StoreID
JOIN DAY D ON D.DayID = SC.DayID
JOIN MALL_STORE MS ON S.StoreID = MS.StoreID
JOIN MALL M ON MS.MallID = M.MallID
JOIN PRODUCT_TYPE PT ON P.ProductTypeID  = PT.ProductTypeID
WHERE M.MallName = 'Northgate Mall'
AND PT.ProductTypeName = 'Shoes'
AND D.DayName = ‘Saturday’


--A. Code to create a stored procedure that inserts a new row into the MANUFACTURER_PRODUCT.

CREATE PROCEDURE usp_ManufacturerProductItem
@ProductName VARCHAR(200),
@PCost NUMERIC(10,5),
@ManuName VARCHAR (150)
AS

DECLARE @ManuID INT = (SELECT ManufacturerID FROM MANUFACTURER
                   WHERE ManufacturerName = @ManuName)
DECLARE @ProductID INT = (SELECT ProductID FROM PRODUCT
                   WHERE ProductName = @ProductName
                   AND Cost = @PCost)

BEGIN TRAN T1
INSERT INTO MANUFACTURER_PRODUCT(ManufacturerID, ProductID)
VALUES(@ManuID, @ProductID)
IF @@ERROR <> 0
   ROLLBACK TRAN T1
ELSE
   COMMIT TRAN T1

--B. Code to create a stored procedure to insert a new row into LINE_ITME.

CREATE PROCEDURE ups_NewLineItem
@ProductName VARCHAR(250),
@PCost NUMERIC(10,5),
@CustFname VARCHAR(150),
@CustLname VARCHAR(150),
@CustEmail VARCHAR(150),
@Quantity VARCHAR(10)
AS

DECLARE @ProductID INT = (SELECT ProductID FROM PRODUCT
                       WHERE ProductName = @ProductName
                       AND Cost = @PCost)
DECLARE @CustomerID INT = (SELECT CustomerID FROM CUSTOMER
                       WHERE CustomerFname = @CustFname
                       AND CustomerLname = @CustLname
                       AND Email = @CustEmail)
DECLARE @OrderID INT = (SELECT OrderID FROM ORDERS
                   WHERE CustomerID = @CustomerID)

BEGIN TRAN T2
INSERT INTO LINE_ITEM(OrderID, ProductID, Quantity)
VALUES(@OrderID, @ProductID, @Quantity)

IF @@ERROR <> 0
   ROLLBACK TRAN T2
ELSE
   COMMIT TRAN T2

-- Q3: In a single order, a customer cannot order more than
-- 10 (quantity) of a particular product.

CREATE FUNCTION fn_NoMoreThan10OfAProduct()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT * FROM PRODUCT P
           JOIN LINE_ITEM LI ON P.ProductID = LI.ProductID
           JOIN ORDERS O ON LI.OrderID = O.OrderID
           GROUP BY O.OrderID
           HAVING COUNT(ProductID) > 10)
           SET @RET = 1
RETURN @RET
END

ALTER TABLE ORDERS
ADD CONSTRAINT NoMoreThan10
CHECK (dbo.fn_NoMoreThan10OfAProduct() = 0)


-- Q4: Computed Column: Calculate the total number of products supplied by a manufacturer:
CREATE FUNCTION fn_NumProductsFromManu(@ManufacturerID INT)
RETURNS INT
AS
BEGIN
DECLARE @RET INT = (SELECT COUNT(P.ProductID) FROM PRODUCT P
                   JOIN MANUFACTURER_PRODUCT MP ON P.ProductID = MP.ProductID
                   JOIN MANUFACTURER M ON MP.ManufacturerID = M.ManufacturerID
                   WHERE M.ManufacturerID = @ManufacturerID)
RETURN @RET
END
GO

ALTER TABLE MANUFACTURER
ADD TotalProducts
AS (dbo.fn_NumProductsFromManu(ManufacturerID))
-- Q5: Code to return the number of customers that have ordered more than 15 products of type Clothing from Northgate Mall in the past 7 days.  

CREATE VIEW vw_CustomerEmailsMoreThan15Purchases
AS
SELECT COUNT(*) AS NumCustomers FROM CUSTOMER C
JOIN ORDERS O ON C.CustomerID = O.CustomerID
JOIN LINE_ITEM LI ON O.OrderID = LI.OrderID
JOIN PRODUCT P ON LI.ProductID = P.ProductID
JOIN STORE_PRODUCT SP ON P.ProductID = SP.ProductID
JOIN STORE S ON SP.StoreID = S.StoreID
JOIN MALL_STORE MS ON S.StoreID = MS.StoreID
JOIN MALL M ON MS.MallID = M.MallID
JOIN PRODUCT_TYPE PT ON P.ProductTypeID  = PT.ProductTypeID
WHERE M.MallName = 'Northgate Mall'
AND PT.ProductTypeName = 'Clothing'
AND DATEDIFF(day, GetDATE(), O.OrderDate) <= 7
GROUP BY C.CustomerID HAVING COUNT(P.ProductID) > 15



