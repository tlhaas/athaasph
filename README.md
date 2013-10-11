athaasph 
========

introduction 
------------

* These are objects for my Hypermedia capstone project. They'll be used with a Sinatra server. 

* Originally everything was scripted on the server, but that got ugly fast. 

* This is the official code refractor, starting from the bottom up.


files
------

* server.rb: This is transiting from v1 to v1, so disregard all the comments.
* MySQLDatabase.rb: a real data layer using the mysql2 gem
* User: represents a person that will be accessing the API (eventually)
* Users: a collection of User objects
* Customer: business customers, but not necessarily users. This is tied to Jobs (estimate/work order/invoice).
* Customers: a collection of Customer objects
* Appointment: an event on a calendar (side bar: WHY NOT CALL IT EVENT THEN?!?!@?!?!111!!!!)
* Appointments: a collection of Appointment objects
* Job: either an Estimate, Work Order, or Invoice.
* Jobs: a collections of Job objects
