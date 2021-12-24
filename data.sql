
--------------
--1.Tạo 1 trigger đặt tên là Tr1, trigger này sẽ được thực thi khi xóa hơn 1 bản ghi dữ liệu từ bảng Customers. Đồng thời, hiển thị thông báo lỗi: 'You are not allowed to delete more than one customer at a time.'
--(Những Customer được xóa là những Customer chưa từng đặt hàng).
create trigger Tr1 on Customers for delete
as
begin
	if @@ROWCOUNT > 1
	begin
		rollback transaction
		raiserror ('You are not allowed to delete more than one customer at a time.', 16, 0)
	end
end

-- Test Tr1
DELETE FROM Customers 
WHERE CustomerID NOT IN (SELECT CustomerID FROM Orders)

--Test trigger:
DELETE FROM Customers 
WHERE CustomerID NOT IN (SELECT CustomerID FROM Orders)

-----------
--2.Tạo 1 trigger đặt tên là Tr2, trigger sẽ được thực thi khi chèn 1 bản ghi dữ liệu vào bảng [Order Details] thì số lượng sản phẩm từ Products có trong kho (UnitsInStock) sẽ được giảm theo số lượng (Quantity) trong [Orders Detail].
create trigger Tr2 on [Order Details] for insert
as
begin
	declare @Quantity int, @ProductID int
	set @Quantity = (select Quantity from inserted)
	set @ProductID = (select ProductID from inserted)
	update Products set UnitsInStock -= @Quantity where ProductID = @ProductID
end

-- Test Tr2
INSERT [Order Details] VALUES (10528, 2, 19.00, 5, 0.2)
INSERT [Order Details] VALUES (10526, 2, 19.00, 2, 0.2)
INSERT [Order Details] VALUES (10527, 2, 19.00, 2, 0.2)
select * from [Order Details] where OrderID in (10526, 10527, 10528)
select * from Products where ProductID = 2


--Test trigger:
INSERT [Order Details] VALUES (10525, 2, 19.00, 5, 0.2)
--------------
--3.Tạo 1 trigger đặt tên là Tr3, trigger sẽ được thực thi khi xóa dữ liệu từ bảng Products. Nếu sản phẩm cần xóa đã được đặt hàng thì không cho phép xóa và hiển thị thông báo: ‘Violate Foreign key reference. Rollback!!!’

create trigger Tr3 on Products for delete
as
begin
	if (select COUNT(*) from [Order Details] where ProductID = (select ProductID from deleted)) > 0
	begin
		rollback transaction
		raiserror('Violate Foreign key reference. Rollback!!!', 16, 0)
	end
end

-- Test Tr3
begin try
	DELETE Products WHERE ProductID = 11
end try
begin catch
	raiserror('Violate Foreign key reference. Rollback!!!', 16, 0)
end catch

--Test trigger: 
DELETE Products WHERE ProductID = 11
---------------------
--4.Tạo 1 bảng mới có lược đồ quan hệ là: PriceTracking(ProductID int, Time DateTime, OldPrice money, NewPrice money).
--Viết 1 Trigger đặt tên Tr4, trigger này sẽ được thực thi khi khi có hoạt động update dữ liệu của UnitPrice trên bảng Products. Đồng thời, trigger cho phép chèn dữ liệu vào bảng PriceTracking với các cột đã có, dữ liệu được chèn phải thoả mãn UnitPrice cần cập nhật phải khác với UnitPrice ban đầu.
create trigger Tr4 on Products for Update
as
begin
	declare @oldPrice money, @newPrice money, @pId int
	set @oldPrice = (select UnitPrice from deleted)
	set @newPrice = (select UnitPrice from inserted)
	set @pId = (select ProductID from deleted)
	insert into PriceTracking values(@pId, GETDATE(), @oldPrice, @newPrice)
end

-- Test Tr4
UPDATE Products set UnitPrice -= 2 where ProductID = 2

select * from Products where ProductID = 2
select * from PriceTracking
--Test trigger:
UPDATE Products
SET UnitPrice = UnitPrice + 2






