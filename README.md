**ServiceMap**

Copyright (C) 2015 DISIT Lab http://www.disit.org - University of Florence

**Dependencies**

- Tomcat 7+
- Mysql 5.5+
- Virtuoso 7.2

**Installation Guide**

- Install Tomcat, Mysql and Virtuoso
- In Mysql create the database ServiceMap and related tables using the bin/ServiceMap.sql
- Copy the file bin/servicemap.properties into the (user home)/servicemap/servicemap.properties (e.g. for tomcat7 /usr/share/tomcat7/servicemap/servicemap.properties)
- Edit the servicemap.properties to set at least the db connection properties (user and password), and the token of mapbox to be used for map requests.
- Build the .war or use the one provided in the bin directory
- Deploy the .war
- Open http://localhost:8080/ServiceMap
- In case of problems you can use http://localhost:8080/ServiceMap/conf.jsp (only from localhost or 192.168.0.x ip address) to see the configuration loaded
- load on Virtuoso all the ontologies present in the ontologies folder under a graph named 'http://www.disit.org/km4city/resource/Ontology'
- in Virtuoso iSQL command line execute "rdfs_rule_set ('urn:ontology', 'http://www.disit.org/km4city/resource/Ontology');"

**KM4City Ontology**

Documentation on the KM4City ontology can be found on http://www.disit.org/km4city/schema and on http://www.disit.org/km4city

The Snap4City platform is based on components based on Km4City framework also on this github. 
Please read the documentation on Snap4City.org to understand which components you need to install 
according to your goals.

Documentation is accessible from Https://www.snap4city.org https://www.km4city.org 
https://www.disit.org Some documentation is also replicated on Https://www.sii-mobility.org

most of the Snap4City components can be provided in form of appliance, please contact Paolo.nesi@unifi.it 
Appliance are in subtance Virtual Machines that you can execute on your premise, fully configure, 
since we provide you full access at level of Root / Admin. The Vm are mainly with Linux like operating system
