create database airlines;
use airlines;

/* Write a query to create a route_details table using suitable data types for the fields, such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and 
distance_miles. Implement the check constraint for the flight number and unique constraint for the route_id fields. Also, make sure that the distance miles field is greater than 0. */
create table route_details(
route_id int,
flight_num int,
origin_airport varchar(10), 
destination_airport varchar(10), 
aircraft_id varchar(10), 
distance_miles int,
check(flight_num>1),
unique(route_id),
check(distance_miles>0)
);
desc route_details;

-- Write a query to display all the passengers (customers) who have travelled in routes 01 to 25. Take data from the passengers_on_flights table.
SELECT 
    customer_id, route_id
FROM
    passengers_on_flights
WHERE
    route_id BETWEEN 01 AND 25
ORDER BY customer_id;

-- Write a query to identify the number of passengers and total revenue in business class from the ticket_details table.
SELECT 
    sum(no_of_tickets) AS 'Number of Passengers',
    sum(no_of_tickets*Price_per_ticket) AS 'Total Revenue'
FROM
    ticket_details
WHERE
    class_id = 'Bussiness';

-- Write a query to display the full name of the customer by extracting the first name and last name from the customer table.
SELECT 
    CONCAT(COALESCE(TRIM(first_name), ''),
            ' ',
            COALESCE(TRIM(last_name), '')) AS 'Full Name'
FROM
    customer;

-- Write a query to extract the customers who have registered and booked a ticket. Use data from the customer and ticket_details tables.
SELECT DISTINCT
    (c.customer_id),
    CONCAT(COALESCE(TRIM(c.first_name), ''),
            ' ',
            COALESCE(TRIM(c.last_name), '')) AS 'Full Name'
FROM
    customer c
        JOIN
    ticket_details t ON c.customer_id = t.customer_id
WHERE
    p_date IS NOT NULL
        AND no_of_tickets IS NOT NULL
ORDER BY c.customer_id;

-- Write a query to identify the customer’s first name and last name based on their customer ID and brand (Emirates) from the ticket_details table.
SELECT DISTINCT
    (c.customer_id), c.first_name, c.last_name
FROM
    customer c
        JOIN
    ticket_details t ON c.customer_id = t.customer_id
WHERE
    t.brand='Emirates'
ORDER BY c.customer_id;

-- Write a query to identify the customers who have travelled by Economy Plus class using Group By and Having clause on the passengers_on_flights table. 
Select customer_id, class_id from passengers_on_flights group by customer_id, class_id having class_id= 'Economy Plus';

-- Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.
SELECT 
    SUM(no_of_tickets * Price_per_ticket) AS 'Revenue',
    IF(SUM(no_of_tickets * Price_per_ticket) > 10000,
        'The revenue has crossed 10000',
        'Sorry, The revenue has not crossed 10000') AS Message
FROM
    ticket_details;

-- Write a query to create and grant access to a new user to perform operations on a database.
CREATE USER 'Surbhi'@'localhost' IDENTIFIED BY 'Surbhi@8';
show privileges;
Grant alter,create,delete,drop,index,insert,select,update,trigger,alter routine,
create routine, execute, create temporary tables ON airlines.* to 'Surbhi'@'localhost';
FLUSH PRIVILEGES;
Show Grants for 'Surbhi'@'localhost';


-- Write a query to find the maximum ticket price for each class using window functions on the ticket_details table. 
Select distinct class_id , Max(Price_per_ticket) over(partition by class_id ) AS Maximum_Ticket_Price 
from ticket_details t;

-- Write a query to extract the passengers whose route ID is 4 by improving the speed and performance of the passengers_on_flights table.
Select * from passengers_on_flights where route_id=4;
create index pof on passengers_on_flights(route_id);
Select * from passengers_on_flights where route_id=4;

-- For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.
Select * from passengers_on_flights where route_id=4;
-- On executing the query from the side bar of the result grid select Execution Plan.

-- Write a query to calculate the total price of all tickets booked by a customer across different aircraft IDs using rollup function. 
Select customer_id, sum(no_of_tickets*Price_per_ticket) AS 'Total Price' from ticket_details group by customer_id with rollup;

-- Write a query to create a view with only business class customers along with the brand of airlines. 
Create view bcb As 
Select customer_id,brand, class_id from ticket_details where class_id='Bussiness';
Select * from bcb order by customer_id;

/*Write a query to create a stored procedure to get the details of all passengers flying between a range of routes defined in run time. 
Also, return an error message if the table doesn't exist.*/
Delimiter $$
create procedure GetDetails(origin text, destination text)
Begin
	DECLARE passengers_table_exists INT;
    DECLARE customer_table_exists INT;
	SELECT COUNT(*) INTO passengers_table_exists FROM information_schema.tables 
	WHERE table_schema = DATABASE() AND table_name = 'passengers_on_flights';
    SELECT COUNT(*) INTO customer_table_exists FROM information_schema.tables 
	WHERE table_schema = DATABASE() AND table_name = 'customer';
	IF passengers_table_exists = 0  or customer_table_exists = 0 THEN
		SELECT 'Error Message: passengers_on_flights table does not exist.' AS Message;
	ElSEIF customer_table_exists = 0 THEN
		SELECT 'Error Message: customer table does not exist.' AS Message;
	ELSE
		Select c.customer_id,c.first_name,c.last_name,c.gender,p.aircraft_id,p.seat_num,
        p.class_id,p.travel_date
        from passengers_on_flights p join customer c on  p.customer_id=c.customer_id
        where depart=origin AND arrival=destination 
		order by customer_id;
	End If;
END$$
call GetDetails('CRW','COD');

-- Write a query to create a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.
Delimiter $$
create procedure RouteDetails()
Begin
	Select * from routes where distance_miles>2000;
END$$
call RouteDetails();

/* 21.	Write a query to create a stored procedure that groups the distance travelled by each flight into three categories. 
The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, intermediate distance travel (IDT) for >2000 AND <=6500, 
and long-distance travel (LDT) for >6500.*/
Delimiter $$
create procedure distance()
Begin
with categorise as
(Select *,
	case
    when distance_miles<= 2000 then 'Short Distance Travel (SDT)'
    when distance_miles>= 6500 then 'Long Distance Travel (LDT)'
    else 'Intermediate Distance Travel (IDT)'
    END  
    As 'Category'
    from routes)
Select Category, count(*) As 'Number of routes' from categorise
    group by Category order by count(*);
END$$
call distance();

/*Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary services are provided for the specific class using a stored function 
in stored procedure on the ticket_details table. 
Condition: 
●	If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No*/
Delimiter $$
Create function service(class text) returns text deterministic
Begin
declare cs text;
if class='Bussiness' or class='Economy Plus' then Set cs= 'Yes';
else set cs='No';
end if;
Return(cs);
End$$ 
Delimiter $$;
Select p_date AS 'Purchase Date',customer_id AS 'Customer Id',class_id AS Class ,service(class_id) AS 'Complimentary Services' from ticket_details order by customer_id;

-- Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.
Delimiter $$
Create procedure cur_extract()
Begin
Declare a text;
Declare b text;
Declare name_cur cursor for
Select first_name,last_name from customer where last_name='Scott';
open name_cur;
repeat
fetch name_cur into a,b;
until b=0
end repeat;
Select a as 'First Name', b as 'Last Name';
close name_cur;
End$$
Delimiter $$;
call cur_extract();
























