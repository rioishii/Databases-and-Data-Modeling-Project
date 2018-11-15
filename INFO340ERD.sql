CREATE TABLE STORE 
(StoreID INT IDENTITY(1,1) primary key,
StoreName varchar(100) not null,
LocationID INT FOREIGN KEY REFERENCES LOCATION (LocationID) not null,
ScheduleID INT FOREIGN KEY REFERENCES SCHEDULE (ScheduleID) not null,
PhoneNumber varchar (20),
StoreTypeID INT FOREIGN KEY REFERENCES STORE_TYPE (StoreTypeID) not null)
GO

CREATE TABLE STORE_TYPE
(StoreTypeID INT IDENTITY(1,1) primary key,
StoreTypeName varchar(100) not null,
StoreTypeDescr varchar(100))
GO

CREATE TABLE LOCATION
(LocationID INT IDENTITY(1,1) primary key,
LocationName varchar(100) not null,
LocationDescr varchar(100))
GO

CREATE TABLE SCHEDULE
(ScheduleID INT IDENTITY(1,1) primary key,
StoreID INT FOREIGN KEY REFERENCES STORE (StoreID) not null,
DayID INT FOREIGN KEY REFERENCES DAY (DayID) not null,
OpenTime TIME not null,
CloseTime TIME not null)
GO

CREATE TABLE DAY
(DayID INT IDENTITY(1,1) primary key,
DayName varchar(100) not null)
GO

CREATE TABLE MALL_STORE
(MallStoreID INT IDENTITY(1,1) primary key,
MallID INT FOREIGN KEY REFERENCES MALL (MallID) not null,
StoreID INT FOREIGN KEY REFERENCES STORE (StoreID) not null) 
GO

CREATE TABLE MALL 
(MallID INT IDENTITY(1,1) primary key,
MallName varchar(100) not null,
MallDescr varchar(100),
MallLocationID INT FOREIGN KEY REFERENCES MALL_LOCATION (MallLocationID) not null)
GO

CREATE TABLE MALL_LOCATION
(MallLocationID INT IDENTITY(1,1) primary key,
MallLocationDescr varchar(100),
Address varchar(100) not null)
GO

CREATE TABLE STORE_PRODUCT 
(StoreProductID INT IDENTITY(1,1) primary key,
StoreID INT FOREIGN KEY REFERENCES STORE (StoreID) not null,
ProductID INT FOREIGN KEY REFERENCES PRODUCT (ProductID) not null)
GO

CREATE TABLE PRODUCT
(ProductID INT IDENTITY(1,1) primary key,
StoreProductID INT FOREIGN KEY REFERENCES STORE_PRODUCT (StoreProductID) not null,
ProductTypeID INT FOREIGN KEY REFERENCES PRODUCT_TYPE (ProductTypeID) not null,
ProductDescr varchar(100) null,
Cost varchar(100))
GO

CREATE TABLE PRODUCT_TYPE
(ProductTypeID INT IDENTITY(1,1) primary key,
ProductTypeName varchar(100) not null,
ProductTypeDescr varchar(100))
GO

CREATE TABLE MANUFACTURER_PRODUCT
(ManufacturerProductID INT IDENTITY(1,1) primary key,
ManufacturerID INT FOREIGN KEY REFERENCES MANUFACTURER (ManufacturerID) not null,
ProductID INT FOREIGN KEY REFERENCES PRODUCT (ProductID) not null)
GO

CREATE TABLE MANUFACTURER
(ManufacturerID INT IDENTITY(1,1) primary key,
ManufacturerName varchar(100) not null)
GO

CREATE TABLE IMAGE
(ImageID INT IDENTITY(1,1) primary key,
Image varchar(100) not null,
ProductID INT FOREIGN KEY REFERENCES PRODUCT (ProductID) not null)
GO

CREATE TABLE REVIEW
(ReviewID INT IDENTITY(1,1) primary key,
ReviewName varchar(100),
ReviewDescr varchar(100),
ProductID INT FOREIGN KEY REFERENCES PRODUCT (ProductID) not null,
RatingID INT FOREIGN KEY REFERENCES RATING (RatingID) not null)
GO

CREATE TABLE RATING
(RatingID INT IDENTITY(1,1) primary key,
Rating INT not null,
ShortName varchar(100) not null,
Descr varchar(100))
GO

CREATE TABLE REVIEW_COMMENT 
(ReviewCommentID INT IDENTITY(1,1) primary key,
ReviewID INT FOREIGN KEY REFERENCES REVIEW (ReviewID) not null,
CommentID INT FOREIGN KEY REFERENCES COMMENT (CommentID) not null,
ReviewDate DATE not null)
GO

CREATE TABLE COMMENT 
(CommentID INT IDENTITY(1,1) primary key,
CommentBody varchar(100) not null)
GO

CREATE TABLE LINE_ITEM
(LineItemID INT IDENTITY(1,1) primary key,
OrderID INT FOREIGN KEY REFERENCES ORDERS (OrderID) not null,
ProductID INT FOREIGN KEY REFERENCES PRODUCT (ProductID) not null,
Quantity INT not null)
GO

CREATE TABLE ORDERS
(OrderID INT IDENTITY(1,1) primary key,
OrderTypeID INT FOREIGN KEY REFERENCES ORDER_TYPE (OrderTypeID) not null,
CustomerID INT FOREIGN KEY REFERENCES CUSTOMER (CustomerID) not null,
OrderDate DATE not null)
GO

CREATE TABLE ORDER_TYPE
(OrderTypeID INT IDENTITY(1,1) primary key,
OrderTypeName varchar(100) not null,
OrderTypeDescr varchar (100))
GO

CREATE TABLE CUSTOMER
(CustomerID INT IDENTITY(1,1) primary key,
CustomerFname varchar(100) not null,
CustomerLname varchar(100) not null,
CustomerAddress varchar(100),
CustomerCity varchar(100),
CustomerState varchar(50),
CustomerZIP varchar(10),
AreaCode INT,
email varchar(100),
DateOfBirth DATE,
PhoneNumber varchar(20),
CreateDate DATE)
GO