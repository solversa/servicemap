<%/* ServiceMap.
   Copyright (C) 2015 DISIT Lab http://www.disit.org - University of Florence

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. */
%>
<%@page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<%@taglib prefix='c' uri='http://java.sun.com/jsp/jstl/core' %>
<%@include file="/include/parameters.jsp" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
    <head>
        <title>ServiceMap</title>
        <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/leaflet-gps.css" type="text/css" />
        <script src='https://api.tiles.mapbox.com/mapbox.js/v2.1.4/mapbox.js'></script>
        <link href='https://api.tiles.mapbox.com/mapbox.js/v2.1.4/mapbox.css' rel='stylesheet' />
        <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>
        <script src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
        <script src="http://code.jquery.com/ui/1.10.4/jquery-ui.js"></script>
        <link rel="stylesheet" href="http://code.jquery.com/ui/1.10.4/themes/smoothness/jquery-ui.css" />	
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/leaflet.awesome-markers.css">
        <script src="${pageContext.request.contextPath}/js/leaflet.awesome-markers.min.js"></script>
        <script src="${pageContext.request.contextPath}/js/leaflet-gps.js"></script>
        <script src="${pageContext.request.contextPath}/js/leaflet.markercluster.js"></script>
        <script src="${pageContext.request.contextPath}/js/mustache.js"></script>
        <script src="${pageContext.request.contextPath}/js/mustache.min.js"></script>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/MarkerCluster.css" type="text/css" />
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/MarkerCluster.Default.css" type="text/css" />
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css" type="text/css" />
    </head>
    <body class="Chrome" onload="getBusLines();
            changeLanguage('ENG')">
        <% if (!gaCode.isEmpty()) {%>
        <script>
            (function (i, s, o, g, r, a, m) {
                i['GoogleAnalyticsObject'] = r;
                i[r] = i[r] || function () {
                    (i[r].q = i[r].q || []).push(arguments)
                }, i[r].l = 1 * new Date();
                a = s.createElement(o),
                        m = s.getElementsByTagName(o)[0];
                a.async = 1;
                a.src = g;
                m.parentNode.insertBefore(a, m)
            })(window, document, 'script', '//www.google-analytics.com/analytics.js', 'ga');
            ga('create', '<%=gaCode%>', 'auto');
            ga('send', 'pageview');
            /*$(document).ready(function () {
             $("input[name='radio-language']").click(function () {
             changeLanguage($(this).val());
             });
             });*/

        </script>
        <% } %>
        <script>
            var mode = "${param.mode}";</script>

        <div id="dialog"></div>        
        <!-- <div id="QueryConfirmSave" title="'Save Query"> <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0; display: none;"></span>Do you want to save this query?</p> </div> !-->
        <div id="map">
            <div class="menu" id="help">
                <a href="http://www.disit.org/servicemap" title="Aiuto Service Map" target="_blank"><img src="${pageContext.request.contextPath}/img/help.png" alt="help SiiMobility ServiceMap" width="28" /></a>
            </div>
        </div>
        <%
            Connection conMySQL = null;
            Statement st = null;
            ResultSet rs = null;
            Connection conMySQL2 = null;
            Statement st2 = null;
            ResultSet rs2 = null;
            Connection conMySQL3 = null;
            Statement st3 = null;
            ResultSet rs3 = null;
            Repository repo = new SPARQLRepository(sparqlEndpoint);
            repo.initialize();
            RepositoryConnection con = repo.getConnection();
        %>
        <div class="menu" id="save">
            <img src="${pageContext.request.contextPath}/img/save.png" alt="Salva la configurazione" width="28" onclick="save_handler(null, null, null, true);" />
        </div>
        <div class="menu" id="embed">
            <img src="${pageContext.request.contextPath}/img/embed_icon.png" alt="Embed Servie Map" width="28" onclick="embedConfiguration();" /> 
        </div>
        <div id="menu-alto" class="menu">
            <div id="lang" value="ENG"><img id="icon_lang"></img></div>
            <div class="header">
                <span name="lbl" caption="Hide_Menu_sx"> - Hide Menu</span>
            </div>
            <div class="content">
                <div id="tabs">
                    <ul>
                        <li><a href="#tabs-1"><span name="lbl" caption="Bus_Search">Florence Bus</span></a></li>
                        <li><a href="#tabs-2"><span name="lbl" caption="Municipality_Search">Tuscan Municipalities</span></a></li>
                            <%-- <li><a href="#tabs-3">Posizione</a></li> --%>
                        <li><a href="#tabs-search"><span name="lbl" caption="Text_Search">Text Search</span></a></li>
                        <li><a href="#tabs-Event"><span name="lbl" caption="Event_Search">Events</span></a></li>
                    </ul>
                    <div id="tabs-1">
                        <div class="use-case-1">
                            <span name="lbl" caption="Select_Line">Select a line</span>:
                            <br/>
                            <!--<select id="elencolinee" name="elencolinee" onchange="mostraElencoFermate(this);"> </select>-->
                            <select id="elencolinee" name="elencolinee" onchange="mostraElencoPercorsi(this);"></select>
                            <br/>
                            <span name="lbl" caption="Select_Route">Select a route</span>:
                            <br/>
                            <!--<select id="elencopercorsi" name="elencopercorsi" onchange="mostraElencoPercorsi(this);"></select>-->
                            <select id="elencopercorsi" name="elencopercorsi" onchange="mostraElencoFermate(this);">
                                <option value=""> - Select a Bus Route -</option>
                            </select>
                            <br/>
                            <span name="lbl" caption="Select_BusStop">Select a bus stop</span>:
                            <br/>
                            <select id="elencofermate" name="elencofermate" onchange="mostraFermate(this);">
                                <option value=""> - Select a Bus Stop - </option>	
                            </select>
                            <div id="pulsanteRT" name="autobusRealTime" onclick="mostraAutobusRT(true);"><span name="lbl" caption="Position_Bus">Position of selected Busses</span></div>
                        </div>
                    </div>
                    <div id="tabs-2">
                        <div class="use-case-2">
                            <span name="lbl" caption="Select_Province">Select a province</span>:
                            <br/>
                            <select id="elencoprovince" name="elencoprovince" onchange="mostraElencoComuni(this);">
                                <option value=""> - Select a Province - </option>
                                <option value="all">ALL THE PROVINCES</option>
                                <option value="AREZZO">AREZZO</option>
                                <option value="FIRENZE">FIRENZE</option>
                                <option value="GROSSETO">GROSSETO</option>
                                <option value="LIVORNO">LIVORNO</option>
                                <option value="LUCCA">LUCCA</option>
                                <option value="MASSA-CARRARA">MASSA-CARRARA</option>
                                <option value="PISA">PISA</option>
                                <option value="PISTOIA">PISTOIA</option>
                                <option value="PRATO">PRATO</option>
                                <option value="SIENA">SIENA</option>
                            </select>
                            <br />
                            <span name="lbl" caption="Select_Municipality">Select a municipality</span>:
                            <br/>
                            <select id="elencocomuni" name="elencocomuni" onchange="updateSelection();
                                    ">
                                <option value=""> - Select a Municipality - </option>
                            </select>
                        </div>
                    </div>
                    <%-- <div id="tabs-3">
                        <div class="use-case-3">Seleziona un punto sulla mappa:
                            <img src="${pageContext.request.contextPath}/img/info.png" alt="Seleziona un punto della mappa" width="26" id="choosePosition" />    
                        </div>
                    </div> --%>
                    <div id="tabs-search">
                        <div class="use-case-search"><span name="lbl" caption="Select_Text_sx">Search by Text</span>:
                            <input type="text" name="search" id="freeSearch" onkeypress="event.keyCode == 13 ? searchText() : false">
                            <br><br><span name="lbl" caption="Num_Results_sx">Max number of results</span>:
                            <select id="numberResults" name="numberResults">
                                <option value="100">100</option>
                                <option value="200">200</option>
                                <option value="500">500</option>
                                <option value="0">No limit</option>
                            </select>
                            <div class="menu" id="serviceTextSearch">
                                <img src="${pageContext.request.contextPath}/img/search_icon.png" alt="Search Services" width="28" onclick="searchText()" />
                            </div>
                            <div class="menu" id="saveQuerySearch">
                                <img src="${pageContext.request.contextPath}/img/save.png" alt="Salva la query" width="28" onclick="save_handler(null, null, null, false, 'freeText');" />
                            </div> 
                        </div>
                    </div>
                    <div id="tabs-Event" style="padding-top:10px;">
                        <span name="lbl" caption="Select_Time">Select a time interval: </span>
                        <input type="radio" name="event_choice" value="day" onchange="searchEvent(this.value, null, null)"><span name="lbl" caption="Day">Day</span></input>
                        <input type="radio" name="event_choice" value="week" onchange="searchEvent(this.value, null, null)"><span name="lbl" caption="Week">Week</span></input>
                        <input type="radio" name="event_choice" value="month" onchange="searchEvent(this.value, null, null)"><span name="lbl" caption="Month">Month</span></input>
                        <fieldset id="event"> 
                            <legend><span name="lbl" caption="Event_Florence">Events in Florence</span></legend>
                            <div id="eventNum" style="display:none;"></div>
                            <div id="eventList"></div>
                        </fieldset>
                    </div>
                    <fieldset id="selection"> 
                        <legend><span name="lbl" caption="Actual_Selection">Actual Selection</span></legend>
                        <span id="selezione" >No selection</span> <br>
                        <div id="approximativeAddress"></div>

                    </fieldset>
                    <div id="queryBox"></div>
                </div>
            </div>
        </div>
        <div id="loading">
            <div id="messaggio-loading">
                <img src="${pageContext.request.contextPath}/img/ajax-loader.gif" width="32" />
                <h3>Loading...</h3>
                <span name=lbl" caption="Loading_Message">Loading may take time</span>
            </div>
        </div>
        <div id="serviceMap_query_toggle"></div>
        <div id="menu-dx" class="menu">
            <div class="header">
                <span name="lbl" caption="Hide_Menu_dx"> - Hide Menu</span>
            </div>
            <div class="content">
                <div id="tabs-servizi">
                    <ul>
                        <li><a href="#tabs-4"><span name="lbl" caption="Search_Regular_Services">Regular Services</span></a></li>
                        <li><a href="#tabs-5"><span name="lbl" caption="Search_Transversal_Services">Transversal Services</span></a></li>
                    </ul>
                    <div id="tabs-4">
                        <div class="use-case-4">
                            <input type="text" name="serviceTextFilter" id="serviceTextFilter" placeholder="search text into service" onkeypress="event.keyCode == 13 ? ricercaServizi('categorie') : false"/><br />
                            <span name="lbl" caption="Services_Categories_R">Services Categories</span> 
                            <br />
                            <input type="checkbox" name="macro-select-all" id="macro-select-all" value="Select All" /> <span name="lbl" caption="Select_All_R">De/Select All</span>
                            <div id="categorie">
                                <%
                                    /*Class.forName("com.mysql.jdbc.Driver");
                                     conMySQL = ConnectionPool.getConnection(); //DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);
                                     System.out.println(urlMySqlDB);
                                     //String query = "SELECT distinct SubClasse FROM SiiMobility.ServiceCategory_menu where SubClasse not like 'SubClasse' order by SubClasse";
                                     String query = "SELECT distinct SubClasse FROM ServiceCategory_menu where Classe not like 'T_Service' AND Visible = 'YES' order by SubClasse";

                                     // create the java statement
                                     st = conMySQL.createStatement();*/
                                    // execute the query, and get a java resultset
                                    //rs = st.executeQuery(query);
                                    // iterate through the java resultset
                                    /*while (rs.next()) {
                                     String classe = rs.getString("SubClasse");
                                     String iniziale = classe.substring(0, 1).toLowerCase();
                                     String classe_ico = iniziale.concat(classe.substring(1, classe.length()));
                                     out.println("<input type='checkbox' name='" + classe + "' value='" + classe + "' class='macrocategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + classe_ico + ".png' height='23' width='20' align='top'> <span class='" + classe + " macrocategory-label'>" + classe + "</span> <span class='toggle-subcategory' title='Mostra sottocategorie'>+</span>");
                                     out.println("<div class='subcategory-content'>");
                                     conMySQL2 = ConnectionPool.getConnection(); //DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);
                                     String query2 = "SELECT distinct Eng FROM ServiceCategory_menu WHERE SubClasse = '" + classe + "' AND Visible = 'YES' ORDER BY Eng ASC";
                                     // create the java statement
                                     st2 = conMySQL2.createStatement();
                                     // execute the query, and get a java resultset
                                     rs2 = st2.executeQuery(query2);
                                     // iterate through the java resultset
                                     while (rs2.next()) {
                                     //String sub_nome = rs2.getString("Ita");
                                     String sub_en_name = rs2.getString("Eng");
                                     String subclasse_ico = classe_ico + "_" + sub_en_name;
                                     //String sub_numero = rs2.getString("NUMERO");
                                     out.println("<input type='checkbox' name='" + sub_en_name + "' value='" + sub_en_name + "' class='sub_" + classe + " subcategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + subclasse_ico + ".png' height='19' width='16' align='top'>");
                                     // modifica per RTZgate
                                     if (sub_en_name.equals("rTZgate")) {
                                     sub_en_name = "RTZgate";
                                     }
                                     out.println("<span class='" + classe + " subcategory-label'>" + sub_en_name + "</span>");
                                     out.println("<br />");
                                     }
                                     out.println("</div>");
                                     out.println("<br />");

                                     st2.close();
                                     conMySQL2.close();
                                     }
                                     st.close();
                                     conMySQL.close();*/
                                    //Class.forName("com.mysql.jdbc.Driver");
                                    conMySQL = ConnectionPool.getConnection(); //DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);
                                    //System.out.println(urlMySqlDB);
                                    String query = "SELECT distinct MacroClass FROM ServiceCategory_menu_NEW where TypeOfService not like 'T_Service' AND Visible = '1' order by MacroClass";

                                    // create the java statement
                                    st = conMySQL.createStatement();

                                    // execute the query, and get a java resultset
                                    rs = st.executeQuery(query);

                                    // iterate through the java resultset
                                    while (rs.next()) {
                                        String macroClass = rs.getString("MacroClass");
                                        //String iniziale = classe.substring(0, 1).toLowerCase();
                                        //String classe_ico = iniziale.concat(classe.substring(1, classe.length()));
                                        out.println("<input type='checkbox' name='" + macroClass + "' value='" + macroClass + "' class='macrocategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + macroClass + ".png' height='23' width='20' align='top'> <span class='" + macroClass + " macrocategory-label'>" + macroClass + "</span> <span class='toggle-subcategory' title='Mostra sottocategorie'>+</span>");
                                        out.println("<div class='subcategory-content'>");
                                        //conMySQL2 = DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);
                                        String query2 = "SELECT distinct SubClass FROM ServiceCategory_menu_NEW WHERE MacroClass = '" + macroClass + "' AND TypeOfService not like 'T_Service' AND Visible = '1' ORDER BY SubClass ASC";
                                        // create the java statement
                                        st2 = conMySQL.createStatement();
                                        // execute the query, and get a java resultset
                                        rs2 = st2.executeQuery(query2);
                                        // iterate through the java resultset
                                        while (rs2.next()) {
                                            //String sub_nome = rs2.getString("Ita");
                                            String subClass = rs2.getString("SubClass");
                                            String subClass_ico = macroClass + "_" + subClass;
                                            //String sub_numero = rs2.getString("NUMERO");
                                            out.println("<input type='checkbox' name='" + subClass + "' value='" + subClass + "' class='sub_" + macroClass + " subcategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + subClass_ico + ".png' height='19' width='16' align='top'>");
                                            // modifica per RTZgate
                                            //if (sub_en_name.equals("rTZgate")) {
                                            //sub_en_name = "RTZgate";
                                            //}
                                            out.println("<span class='" + macroClass + " subcategory-label'>" + subClass + "</span>");
                                            out.println("<br />");
                                        }
                                        out.println("</div>");
                                        out.println("<br />");

                                        st2.close();
                                        //conMySQL2.close();
                                    }
                                    st.close();
                                    conMySQL.close();


                                %>
                                <br />

                            </div>
                            <span name="lbl" caption="Num_Results_dx_R">N. results</span>:
                            <select id="nResultsServizi" name="nResultsServizi">
                                <option value="10">10</option>
                                <option value="20">20</option>
                                <option value="50">50</option>
                                <option value="100" selected="selected">100</option>
                                <option value="200">200</option>
                                <option value="500">500</option>
                                <option value="0">No Limit</option>
                            </select>
                            <br />
                            <hr />

<!-- <input type="checkbox" name="road-sensor" value="RoadSensor" id="Sensor" class="macrocategory" /> <img src='${pageContext.request.contextPath}/img/mapicons/RoadSensor.png' height='19' width='16' align='top'/> <span class="road-sensor macrocategory-label">Road Sensors</span> 
<br />
<br />
N. risultati:
<select id="nResultsSensor" name="nResultsSensor">
    <option value="10">10</option>
    <option value="20">20</option>
    <option value="50">50</option>
    <option value="100" selected="selected">100</option>
    <option value="200">200</option>
    <option value="500">500</option>
    <option value="0">Nessun Limite</option>
</select>
<hr />
<input type="checkbox" name="near-bus-stops" value="NearBusStops" class="macrocategory" id="Bus" /> <img src='${pageContext.request.contextPath}/img/mapicons/NearBusStop.png' height='19' width='16' align='top'/> <span class="near-bus-stops macrocategory-label">Bus Stops</span>
<br />
<br />
N. risultati:
<select id="nResultsBus" name="nResultsBus">
    <option value="10">10</option>
    <option value="20">20</option>
    <option value="50">50</option>
    <option value="100" selected="selected">100</option>
    <option value="200">200</option>
    <option value="500">500</option>
    <option value="0">Nessun Limite</option>
</select>
<hr />-->
                            <span name="lbl" caption="Search_Range_R">Search range</span>
                            <select id="raggioricerca" name="raggioricerca">
                                <option value="0.1">100 mt</option>
                                <option value="0.2">200 mt</option>
                                <option value="0.3">300 mt</option>
                                <option value="0.5">500 mt</option>
                                <option value="1">1 km</option>
                                <option value="2">2 km</option>
                                <option value="5">5 km</option>
                                <option value="area">visible areas</option>
                            </select>
                            <hr />
                            <!--<input type="button" value="Cerca!" id="pulsante-ricerca" onclick="ricercaServizi();" />
                             <input type="button" value="Pulisci" id="pulsante-reset" onclick="resetTotale();" /> !-->
                            <div class="menu" id="serviceSearch">
                                <img src="${pageContext.request.contextPath}/img/search_icon.png" alt="Search Services" width="28" onclick="ricercaServizi('categorie');" />
                            </div>
                            <div class="menu" id="clearAll">
                                <img src="${pageContext.request.contextPath}/img/clear_icon.png" alt="Clear all" width="28" onclick="resetTotale();" />
                            </div>
                            <div class="menu" id="saveQuery">
                                <img src="${pageContext.request.contextPath}/img/save.png" alt="Salva la query" width="28" onclick="save_handler();" />
                            </div>
                            <br />

                        </div>
                    </div>
                    <div id="tabs-5">
                        <div class="use-case-5">
                            <!--<h3>Coming soon...</h3>-->
                            <!-- AGGIUNTA TRANSVERSAL SERVICES -->
                            <input type="text" name="serviceTextFilter_t" id="serviceTextFilter_t" placeholder="search text into service" onkeypress="event.keyCode == 13 ? ricercaServizi('categorie_t') : false"/><br />
                            <span name="lbl" caption="Services_Categories_T">Services Categories</span> 
                            <br />
                            <input type="checkbox" name="macro-select-all_t" id="macro-select-all_t" value="Select All" /> <span name="lbl" caption="Select_All_T">De/Select All</span>
                            <div id="categorie_t">
                                <br />
                                <%                                    //Class.forName("com.mysql.jdbc.Driver");
                                    conMySQL = ConnectionPool.getConnection(); //DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);

                                    String query_T = "SELECT distinct MacroClass FROM ServiceCategory_menu_NEW where TypeOfService not like 'Service' AND Visible = '1' order by MacroClass";

                                    // create the java statement
                                    st = conMySQL.createStatement();

                                    // execute the query, and get a java resultset
                                    rs = st.executeQuery(query_T);

                                    // iterate through the java resultset
                                    while (rs.next()) {
                                        String classe = rs.getString("MacroClass");
                                        //String iniziale = classe.substring(0, 1).toLowerCase();
                                        //String classe_ico = iniziale.concat(classe.substring(1, classe.length()));
                                        out.println("<input type='checkbox' name='" + classe + "' value='" + classe + "' class='macrocategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + classe + ".png' height='23' width='20' align='top'> <span class='" + classe + " macrocategory-label'>" + classe + "</span> <span class='toggle-subcategory' title='Mostra sottocategorie'>+</span>");
                                        out.println("<div class='subcategory-content'>");
                                        //conMySQL2 = DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);
                                        String query2 = "SELECT distinct labelITA, SubClass FROM ServiceCategory_menu_NEW WHERE MacroClass = '" + classe + "' AND Visible = '1' ORDER BY SubClass ASC";
                                        // create the java statement
                                        st2 = conMySQL.createStatement();
                                        // execute the query, and get a java resultset
                                        rs2 = st2.executeQuery(query2);
                                        // iterate through the java resultset
                                        while (rs2.next()) {
                                            //String sub_nome = rs2.getString("Ita");
                                            String sub_en_name = rs2.getString("SubClass");
                                            //String subclasse_ico = classe_ico + "_" + sub_en_name;

                                            //conMySQL3 = DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);
                                            if (sub_en_name.equals("Event")) {
                                                String subclasse_ico = "HappeningNow_" + sub_en_name;
                                                out.println("<input type='checkbox' name='" + sub_en_name + "' value='" + sub_en_name + "' class='sub_" + classe + " subcategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + subclasse_ico + ".png' height='19' width='16' align='top'>");
                                                out.println("<span class='" + classe + " subcategory-label'>" + sub_en_name + "</span>");
                                                out.println("<br />");
                                            } else {
                                                String query3 = "SELECT distinct MacroClass FROM ServiceCategory_menu_NEW WHERE SubClass = '" + sub_en_name + "' AND TypeOfService not like 'T_Service'";
                                                st3 = conMySQL.createStatement();
                                                rs3 = st3.executeQuery(query3);
                                                while (rs3.next()) {
                                                    String macro_cat = rs3.getString("MacroClass");

                                                    //String subclasse_ico = (macro_cat.substring(0, 1).toLowerCase()).concat(macro_cat.substring(1, macro_cat.length())) + "_" + sub_en_name;
                                                    String subclasse_ico = macro_cat + "_" + sub_en_name;

                                                    out.println("<input type='checkbox' name='" + sub_en_name + "' value='" + sub_en_name + "' class='sub_" + classe + " subcategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + subclasse_ico + ".png' height='19' width='16' align='top'>");
                                                    out.println("<span class='" + classe + " subcategory-label'>" + sub_en_name + "</span>");
                                                    out.println("<br />");
                                                }
                                            }
                                            //String macro_cat = rs3.getString("SubClasse");
                                            //System.out.println("res3_macrocat:" + macro_cat);
                                            //String subclasse_ico = (macro_cat.substring(0, 1).toLowerCase()).concat(macro_cat.substring(1, classe.length()))+ "_" + sub_en_name;
                                            //String sub_numero = rs2.getString("NUMERO");
                                            //out.println("<input type='checkbox' name='" + sub_en_name + "' value='" + sub_en_name + "' class='sub_" + classe + " subcategory' /> <img src='" + request.getContextPath() + "/img/mapicons/" + subclasse_ico + ".png' height='19' width='16' align='top'>");
                                            //out.println("<span class='" + classe + " subcategory-label'>" + sub_en_name + "</span>");
                                            //out.println("<br />");

                                            st3.close();
                                            //conMySQL3.close();
                                        }

                                        out.println("</div>");
                                        out.println("<br />");

                                        st2.close();
                                        //conMySQL2.close();
                                    }
                                    st.close();
                                    conMySQL.close();
                                %>
                                <input type="checkbox" name="fresh-place" value="Fresh_place" id="FreshPlace" class="macrocategory" /> <img src='${pageContext.request.contextPath}/img/mapicons/TourismService_Fresh_place.png' height='23' width='20' align='top''/> <span class="fresh-place macrocategory-label">Fresh Place</span>
                                <br/>
                                <input type="checkbox" name="public-transport-line" value="PublicTransportLine" id="PublicTransportLine" class="macrocategory" /> <img src='${pageContext.request.contextPath}/img/mapicons/TransferServiceAndRenting_Urban_bus.png' height='23' width='20' align='top''/> <span class="public-transport-line macrocategory-label">Public Transport Line</span> 
                                <br />
                                <input type="checkbox" name="road-sensor" value="SensorSite" id="Sensor" class="macrocategory" /> <img src='${pageContext.request.contextPath}/img/mapicons/TransferServiceAndRenting_SensorSite.png' height='23' width='20' align='top''/> <span class="road-sensor macrocategory-label">Road Sensors</span> 
                                <br />
                                <input type="checkbox" name="near-bus-stops" value="BusStop" class="macrocategory" id="Bus" /> <img src='${pageContext.request.contextPath}/img/mapicons/TransferServiceAndRenting_BusStop.png' height='23' width='20' align='top'/> <span class="near-bus-stops macrocategory-label">Bus Stops</span>
                                
                            </div>
                            <br />
                            <span name="lbl" caption="Num_Results_dx_T">N. results for each</span>:
                            <select id="nResultsServizi_t" name="nResultsServizi">
                                <option value="10">10</option>
                                <option value="20">20</option>
                                <option value="50">50</option>
                                <option value="100" selected="selected">100</option>
                                <option value="200">200</option>
                                <option value="500">500</option>
                                <option value="0">No Limit</option>
                            </select>
                            <br />
                            <!--
                                                    Raggio di Ricerca: 
                                                    <br />
                                                    <select id="raggioricerca" name="raggioricerca">
                                                        <option value="0.1">100 metri</option>
                                                        <option value="0.2">200 metri</option>
                                                        <option value="0.3">300 metri</option>
                                                        <option value="0.5">500 metri</option>
                                                        <option value="1">1 km</option>
                                                        <option value="2">2 km</option>
                                                        <option value="5">5 km</option>
                                                    </select>
                                                    <br />
                                                    Numero massimo di risultati:
                                                    <br />
                                                    <select id="numerorisultati" name="numerorisultati">
                                                        <option value="100">100</option>
                                                        <option value="200">200</option>
                                                        <option value="500">500</option>
                                                        <option value="0">Nessun Limite</option>
                                                    </select>
                            
                                                    <br />
                                                    <hr />
                            !-->
                            <!-- da decommentare --> 
                            <hr />
                            <span name="lbl" caption="Search_Range_T">Search Range</span>
                            <select id="raggioricerca_t" name="raggioricerca">
                                <option value="0.1">100 mt</option>
                                <option value="0.2">200 mt</option>
                                <option value="0.3">300 mt</option>
                                <option value="0.5">500 mt</option>
                                <option value="1">1 km</option>
                                <option value="2">2 km</option>
                                <option value="5">5 km</option>
                                <option value="area">visible areas</option>
                            </select>
                            <hr />
                            <div class="menu" id="serviceSearch">
                                <img src="${pageContext.request.contextPath}/img/search_icon.png" alt="Search Services" width="28" onclick="ricercaServizi('categorie_t');" />
                            </div>
                            <!--<div class="menu" id="textSearch">
                                <img src="${pageContext.request.contextPath}/img/text_search.jpg" alt="Text Search" width="28" onclick="showTextSearchDialog();" />
                            </div>-->
                            <div class="menu" id="clearAll">
                                <img src="${pageContext.request.contextPath}/img/clear_icon.png" alt="Clear all" width="28" onclick="resetTotale();" />
                            </div>
                            <!--<input type="checkbox" name="open_path" value="open_path" id="apri_path" />  <span>Open Path/Area</span>-->
                            <!-- DA DECOMMENTARE QUANDO SARA' FATTO IL SALVATAGGIO DEI SERVIZI TRASVERSALI -->
                            <!-- <div class="menu" id="saveQuery">
                              <img src="${pageContext.request.contextPath}/img/save.png" alt="Salva la query" width="28" onclick="save_handler();" />
                            </div> -->
                            <br />

                        </div>
                    </div>
                </div>
                <fieldset id="searchOutput"> 
                    <legend><span name="lbl" caption="Search_Results">Search Results</span></legend>
                    <div class="result" id="cluster-msg"></div>
                    <div class="result" id="msg"></div>
                    <div class="result" id="serviceRes"><img src='${pageContext.request.contextPath}/img/mapicons/TourismService.png' height='21' width='18' align='top'/><span class="label">Services:</span><div class="value"></div></div>
                    <div class="result" id="busstopRes"><img src='${pageContext.request.contextPath}/img/mapicons/TransferServiceAndRenting_BusStop.png' height='21' width='18' align='top'/><span class="label">Bus Stops:</span><div class="value"></div></div>
                    <div class="result" id="busDirection"><span class="label">Direction:</span><div class="value"></div></div>
                    <div class="result" id="sensorRes"><img src='${pageContext.request.contextPath}/img/mapicons/TransferServiceAndRenting_SensorSite.png' height='21' width='18' align='top'/><span class="label">Road Sensors:</span><div class="value"></div></div>
                </fieldset>
                <fieldset id="resultTPL"> 
                    <legend><span name="lbl" caption="Results_BusLines">Bus Lines</span></legend>
                    <div id="numTPL" style="display:none;"></div>
                    <div id="listTPL"></div>
                </fieldset>

            </div>
        </div>
        <div id="info-aggiuntive" class="menu">
            <div class="header"><span name="lbl" caption="Hide_Menu_meteo"> - Hide Menu</span>
            </div>
            <div class="content"></div>
        </div>
        <!--  CARICAMENTO DEL FILE utility.js CON FUNZIONI NECESSARIE  -->
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/utility.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/save_embed.js"></script>
        <script>
                                    // $("#embed").hide();
                                    var ctx = "${pageContext.request.contextPath}";
                                    //var ctx = "http://servicemap.disit.org/WebAppGrafo";
                                    var query = new Object();
                                    var parentQuery = "";
                                    var listOfPopUpOpen = [];
                                    var pins = "";
                                    var save_operation = "";
                                    var user_mail = "";
                                    var queryTitle = "";
                                    var description = "";
                                    var currentServiceUri = ""
                                    var currentIdConf = null;
                                    var lastEmail = "";
                                    Array.prototype.equals = function (array) {
                                        // if the other array is a falsy value, return
                                        if (!array)
                                            return false;
                                        // compare lengths - can save a lot of time 
                                        if (this.length != array.length)
                                            return false;
                                        for (var i = 0, l = this.length; i < l; i++) {
                                            // Check if we have nested arrays
                                            if (this[i] instanceof Array && array[i] instanceof Array) {
                                                // recurse into the nested arrays
                                                if (!this[i].equals(array[i]))
                                                    return false;
                                            }
                                            else if (this[i] != array[i]) {
                                                // Warning - two different object instances will never be equal: {x:20} != {x:20}
                                                return false;
                                            }
                                        }
                                        return true;
                                    }
                                    function parseUrlQuery(queryString) {
                                        var params = {}, queries, temp, i, l;
                                        // Split into key/value pairs
                                        queries = queryString.split("&");
                                        // Convert the array of strings into an object
                                        for (i = 0, l = queries.length; i < l; i++) {
                                            temp = queries[i].split('=');
                                            params[temp[0]] = temp[1];
                                        }
                                        return params;
                                    }
                                    function include(arr, obj) {
                                        return (arr.indexOf(obj) != -1);
                                    }
                                    function saveQueryFreeText(text, limit) {
                                        var lastQuery = new Object();
                                        lastQuery["text"] = text;
                                        lastQuery["limit"] = limit;
                                        lastQuery["type"] = "freeText";
                                        return lastQuery;
                                    }
                                    function searchText() {
                                        nascondiRisultati();
                                        var numeroEventi = 0;
                                        var text = $("#freeSearch").val();
                                        var textEv = $("#freeSearch").val();
                                        var limit = $("#numberResults").val();
                                        var numService = 0;
                                        var numBusstop = 0;
                                        var numSensor = 0;
                                        text = escape(text);
                                        $('#loading').show();
                                        svuotaLayers();
                                        query = saveQueryFreeText(text, limit);
                                        numeroEventi = searchEvent("free_text", null, null, limit, textEv);
                                        if (numeroEventi != 0) {
                                            //risultatiRicerca((numService+numeroEventi), 0, 0, 1);
                                            if(limit!=0)
                                              limit = (limit - numeroEventi);
                                            $("input[name=event_choice][value=day]").attr('checked', 'checked');
                                        }
                                        $.ajax({
                                            data: {
                                                search: text,
                                                limit: limit
                                            },
                                            url: ctx + "/ajax/json/free-text-search.jsp",
                                            type: "GET",
                                            dataType: 'json',
                                            async: true,
                                            success: function (data) {
                                                /*numeroEventi = searchEvent("free_text", null, null, limit, textEv);
                                                 if(numeroEventi != 0){
                                                 risultatiRicerca((numService+numeroEventi), 0, 0, 1);
                                                 limit = (limit - numeroEventi);
                                                 $("input[name=event_choice][value=day]").attr('checked', 'checked');
                                                 }*/
                                                var array = new Array();
                                                         var delta = new Array();
                                                        var sin = new Array();
                                                        var cos = new Array();
                                                        var sx = new Array();
                                                        var dx = new Array();
                                                        var fract = 0.523599;
                                                        var dist = 1.2;
                                                        var passo = 0.00007;
                                                        
                                                        for (var r = 0; r < data.features.length; r++) {
                                                            array[r] = new Array();
                                                            for (var c = 0; c < 2; c++) {
                                                                array[r][c] = 0;
                                                            }
                                                            delta[r] = 0;
                                                            sin[r] = 0;
                                                            cos[r] = 0;
                                                            sx[r] = 0;
                                                            dx[r] = 0;
                                                        }
                                                var i = 0;        
                                                if (data.features.length > 0) {
                                                    var count = 0;
                                                            for (i = 0; i < data.features.length; i++) {
                                                                if (data.features[i].properties.serviceType == 'TourismService_Tourist_trail') {
                                                                    if (count == 0) {
                                                                        array[0][0] = data.features[i].geometry.coordinates[0];
                                                                        array[0][1] = data.features[i].geometry.coordinates[1];
                                                                    } else {
                                                                        for (var k = 0; k < count; k++) {
                                                                            if ((data.features[i].geometry.coordinates[0] == array[k][0]) && (data.features[i].geometry.coordinates[1] == array[k][1])) {
                                                                                //array[count][0] = data.features[i].geometry.coordinates[0] + (Math.random() - .4) / 1500;
                                                                                //array[count][1] = data.features[i].geometry.coordinates[1] + (Math.random() - .4) / 1500;
                                                                                //data.features[i].geometry.coordinates[0] = array[count][0];
                                                                                //data.features[i].geometry.coordinates[1] = array[count][1];
                                                                                delta[count] = (fract*count);
                                                                                sin[count] = Math.sin(delta[count]);
                                                                                cos[count] = Math.cos(delta[count]);
                                                                                sx[count] = (sin[count]*passo*dist*count);
                                                                                dx[count] = (cos[count]*passo*dist*count);
                                                                                
                                                                                array[count][0] = (array[0][0])+sx[count];
                                                                                array[count][1] = (array[0][1])+dx[count];
                                                                                data.features[i].geometry.coordinates[0] = array[count][0];
                                                                                data.features[i].geometry.coordinates[1] = array[count][1];
                                                                            } else {
                                                                                array[count][0] = data.features[i].geometry.coordinates[0];
                                                                                array[count][1] = data.features[i].geometry.coordinates[1];
                                                                            }

                                                                        }

                                                                    }
                                                                    count++;
                                                                }

                                                            }
                                                    servicesLayer = L.geoJson(data, {
                                                        pointToLayer: function (feature, latlng) {
                                                            marker = showmarker(feature, latlng);
                                                            return marker;
                                                        },
                                                        onEachFeature: function (feature, layer) {
                                                            popupContent = "";
                                                            var divId = feature.id + "-" + feature.properties.tipo;
                                                            if (feature.properties.type == "Strada") {
                                                                popupContent = popupContent + "<h3>" + feature.properties.nome + " n. " + feature.properties.number + "</h3>";
                                                            }
                                                            popupContent = popupContent + "<div id=\"" + divId + "\" ></div>";
                                                            layer.bindPopup(popupContent);
                                                            numService++;
                                                            /*if (feature.properties.serviceType == "NearBusStop") {
                                                             numBusstop++;
                                                             }
                                                             else {
                                                             if (feature.properties.serviceType == "RoadSensor")
                                                             numSensor++;
                                                             else
                                                             numService++;
                                                             }*/

                                                        }
                                                    });
            <%if (clusterResults > 0) {%>
                                                    if (data.features.length >=<%=clusterResults%>) {
                                                        markers = new L.MarkerClusterGroup({maxClusterRadius: <%=clusterDistance%>, disableClusteringAtZoom: <%=noClusterAtZoom%>});
                                                        servicesLayer = markers.addLayer(servicesLayer);
                                                        //$("#cluster-msg").text("pi� di <%=clusterResults%> risultati, attivato clustering");
                                                        $("#cluster-msg").text("more than <%=clusterResults%> results, clustering enable");
                                                        $("#cluster-msg").show();
                                                    }
                                                    else
                                                        $("#cluster-msg").hide();
            <%}%>
                                                    servicesLayer.addTo(map);
                                                    var confiniMappa = servicesLayer.getBounds();
                                                    map.fitBounds(confiniMappa, {padding: [50, 50]});
                                                    $('#loading').hide();
                                                    risultatiRicerca(numService + numeroEventi, 0, 0, 1);
                                                }
                                                else {
                                                    $('#loading').hide();
                                                    //risultatiRicerca(numService, numBusstop, numSensor, 1);
                                                    if (numeroEventi == 0) {
                                                        risultatiRicerca(0, 0, 0, 0);
                                                    } else {
                                                        risultatiRicerca(numeroEventi, 0, 0, 1);
                                                    }
                                                }
                                                /*numeroEventi = searchEvent("free_text", null, null, limit, textEv);
                                                 if(numeroEventi != 0){
                                                 risultatiRicerca((numService+numeroEventi), 0, 0, 1);
                                                 $("input[name=event_choice][value=day]").attr('checked', 'checked');
                                                 }*/
                                            },
                                            error: function (request, status, error) {
                                                $('#loading').hide();
                                                console.log(error);
                                                alert('Error in searching ' + decodeURIComponent(text) + "\n The error is " + error + " " + status);
                                            }
                                        });
                                    }

                                    function showResults(parameters) {
                                        if (mode != "embed") {
                                            var queryId = parameters["queryId"];
                                            if (queryId != null) {
                                                $.ajax({
                                                    data: {
                                                        queryId: queryId
                                                    },
                                                    url: ctx + "/api/query.jsp",
                                                    type: "GET",
                                                    async: true,
                                                    dataType: 'json',
                                                    success: function (msg) {
                                                        /*     if(msg.idService != "null" && msg.idService != ""){
                                                         showService(msg.idService,msg.typeService);
                                                         }*/
                                                        queryTitle = msg.title;
                                                        description = msg.description;
                                                        user_mail = msg.email;
                                                        var htmlQueryBox = "<hr><h2>" + queryTitle + "</h2><p>" + description + "</p>";
                                                        $("#queryBox").append(htmlQueryBox);
                                                        if (!msg.isReadOnly)
                                                            save_operation = "write";
                                                        var typeSaving = msg.typeSaving;
                                                        if (typeSaving == "service") {
                                                            showService(unescape(msg.idService));
                                                        } else if (typeSaving == "freeText") {
                                                            $("#freeSearch").val(msg.text);
                                                            $("#numberResults").val(msg.numeroRisultatiServizi);
                                                            showResultsFreeSearch(msg.text, msg.numeroRisultatiServizi);
                                                        } else {
                                                            parentQuery = msg.parentQuery;
                                                            if (msg.nomeProvincia != "") {
                                                                $("#elencoprovince").val(msg.nomeProvincia);
                                                                mostraElencoComuni(msg.nomeProvincia, msg.nomeComune);
                                                            }
                                                            if (msg.line != "" && msg.line != null && msg.line != "null") {
                                                                getBusLines("query");
                                                                $("#elencolinee").val(msg.line);
                                                                mostraElencoFermate(msg.line, msg.stop);
                                                            }
                                                            var categorie = msg.categorie;
                                                            $("#categorie :not(:checked)").each(function () {
                                                                var category = $(this).val();
                                                                if (categorie.indexOf(category) > -1)
                                                                    $(this).attr("checked", true);
                                                            });
                                                            if (categorie.indexOf("NearBusStops") > -1)
                                                                $("#Bus").attr("checked", true);
                                                            if (categorie.indexOf("RoadSensor") > -1)
                                                                $("#Sensor").attr("checked", true);
                                                            var categorieArray = categorie.split(",");
                                                            var stringaCategorie = categorieArray.join(";");
                                                            stringaCategorie = stringaCategorie.replace("[", "");
                                                            stringaCategorie = stringaCategorie.replace("]", "");
                                                            stringaCategorie = stringaCategorie.replace(/\s+/g, '');
                                                            $("#raggioricerca").val(msg.raggioServizi);
                                                            $("#nResultsServizi").val(msg.numeroRisultatiServizi);
                                                            $("#nResultsSensori").val(msg.numeroRisultatiSensori);
                                                            $("#nResultsBus").val(msg.numeroRisultatiBus);
                                                            var text = msg.text;
                                                            $("#serviceTextFilter").val(text);
                                                            $('#selezione').html(msg.actualSelection);
                                                            selezione = unescape(msg.actualSelection);
                                                            if (typeSaving == "embed" && selezione.indexOf("COMUNE di") != -1)
                                                                coordinateSelezione = null;
                                                            else
                                                                coordinateSelezione = unescape(msg.coordinateSelezione);
                                                            //  if(msg.idService == "null" || msg.idService == "" || msg.idService== null)
                                                            if (stringaCategorie != "null")
                                                                mostraServiziAJAX_new(stringaCategorie, msg.actualSelection, coordinateSelezione, msg.nomeComune, msg.numeroRisultatiServizi, msg.numeroRisultatiSensori, msg.numeroRisultatiBus, msg.raggioServizi, msg.raggioSensori, msg.raggioBus, null, text, "categorie");
                                                        }
                                                    }
                                                });
                                            } else if (parameters["selection"] != null) {
                                                var selection = unescape(parameters["selection"]);
                                                if (selection == "undefined")
                                                    selection = "";
                                                var categorie = unescape(parameters["categories"]);
                                                if (categorie == "undefined")
                                                    categorie = "Service;RoadSensor;NearBusStops";
                                                var text = unescape(parameters["text"]);
                                                if (text == "undefined")
                                                    text = "";
                                                var risultati = unescape(parameters["maxResults"]);
                                                if (risultati == "undefined" || risultati == "")
                                                    risultati = "100";
                                                var arrayRisultati = risultati.split(";");
                                                var risultatiServizi = arrayRisultati[0];
                                                var risultatiSensori = (arrayRisultati.length >= 2 ? arrayRisultati[1] : risultatiServizi);
                                                var risultatiBus = (arrayRisultati.length >= 3 ? arrayRisultati[2] : risultatiSensori);
                                                var raggi = unescape(parameters["maxDists"]);
                                                if (raggi == "undefined" || raggi == "")
                                                    raggi = "0.1";
                                                var arrayRaggi = raggi.split(";");
                                                var raggioServizi = arrayRaggi[0];
                                                var raggioSensori = (arrayRaggi.length >= 2 ? arrayRaggi[1] : raggioServizi);
                                                var raggioBus = (arrayRaggi.length >= 3 ? arrayRaggi[2] : raggioSensori);
                                                if (selection.toLowerCase().indexOf("comune di") != -1 || selection == "") {
                                                    var nomeComune = selection.substring(selection.indexOf("COMUNE di") + 10);
                                                    mostraServiziAJAX_new(categorie, selection, coordSel, nomeComune, risultatiServizi, risultatiSensori, risultatiBus, raggioServizi, raggioSensori, raggioBus, null, text, "categorie");
                                                } else {
                                                    if (selection.indexOf("http://") != -1) {
                                                        var coordSel = "";
                                                        $.ajax({
                                                            data: {
                                                                serviceUri: selection
                                                            },
                                                            url: ctx + "/ajax/getCoordinates.jsp",
                                                            type: "GET",
                                                            dataType: 'json',
                                                            async: true,
                                                            success: function (msg) {
                                                                coordSel = msg.latitudine + ";" + msg.longitudine;
                                                                selection = "point";
                                                                mostraServiziAJAX_new(categorie, selection, coordSel, nomeComune, risultatiServizi, risultatiSensori, risultatiBus, raggioServizi, raggioSensori, raggioBus, null, text, "categorie");
                                                            }
                                                        });
                                                    }
                                                    else {
                                                        var coordSel = selection;
                                                        selection = "point";
                                                        mostraServiziAJAX_new(categorie, selection, coordSel, nomeComune, risultatiServizi, risultatiSensori, risultatiBus, raggioServizi, raggioSensori, raggioBus, null, text, "categorie");
                                                    }
                                                }
                                            } else if (parameters["search"] != null) {
                                                var textToSearch = unescape(parameters["search"]);
                                                var limit = parameters["maxResults"];
                                                if (limit == undefined)
                                                    limit = parameters["limit"];
                                                if (limit == undefined)
                                                    limit = "100";
                                                showResultsFreeSearch(textToSearch, limit);
                                            } else if (parameters["serviceUri"] != null) {
                                                var idServices = parameters["serviceUri"].split(";");
                                                //loadServiceInfo(idService)
                                                for (var i = 0; i < idServices.length; i++)
                                                    showService(idServices[i]);
                                            }
                                            else {
                                                alert("invalid API call");
                                            }
                                        } else { //mode=="embed"
                                            var idConf = parameters["idConf"];
                                            if (idConf != null) {
                                                $.ajax({
                                                    data: {
                                                        idConf: idConf
                                                    },
                                                    url: ctx + "/api/embed/configuration.jsp",
                                                    type: "GET",
                                                    async: true,
                                                    dataType: 'json',
                                                    success: function (msg) {
                                                        if (msg.weatherCity != "null" && msg.weatherCity != "") {
                                                            $.ajax({
                                                                url: "${pageContext.request.contextPath}/ajax/get-weather.jsp",
                                                                type: "GET",
                                                                async: true,
                                                                data: {
                                                                    nomeComune: msg.weatherCity
                                                                },
                                                                success: function (msg) {
                                                                    $('#info-aggiuntive .content').html(msg);
                                                                }
                                                            });
                                                        }
                                                        queryTitle = msg.title;
                                                        description = msg.description;
                                                        user_mail = msg.email;
                                                        var textToSearch = msg.text;
                                                        var c = unescape(msg.center);
                                                        var center = JSON.parse(c);
                                                        map.setView(new L.LatLng(center.lat, center.lng), msg.zoom);
                                                        var htmlQueryBox = "<hr><h2>" + queryTitle + "</h2><p>" + description + "</p>";
                                                        $("#queryBox").append(htmlQueryBox);
                                                        if (msg.nomeProvincia != "" && msg.nomeProvincia != "null") {
                                                            $("#elencoprovince").val(msg.nomeProvincia);
                                                            mostraElencoComuni(msg.nomeProvincia, msg.nomeComune);
                                                            $("#tabs").tabs("option", "active", 1);
                                                        }
                                                        if (msg.line != null && msg.line != "" && msg.line != "null") {
                                                            getBusLines("query");
                                                            $("#tabs").tabs("option", "active", 0);
                                                            $("#elencolinee").val(msg.line);
                                                            mostraElencoFermate(msg.line, msg.stop);
                                                        }
                                                        var categorie = msg.categorie;
                                                        $("#categorie :not(:checked)").each(function () {
                                                            var category = $(this).val();
                                                            if (categorie.indexOf(category) > -1)
                                                                $(this).attr("checked", true);
                                                        });
                                                        if (categorie.indexOf("NearBusStops") > -1)
                                                            $("#Bus").attr("checked", true);
                                                        if (categorie.indexOf("RoadSensor") > -1)
                                                            $("#Sensor").attr("checked", true);
                                                        $("#raggioricerca").val(msg.raggioServizi);
                                                        $("#nResultsServizi").val(msg.numeroRisultatiServizi);
                                                        $("#nResultsSensori").val(msg.numeroRisultatiSensori);
                                                        $("#nResultsBus").val(msg.numeroRisultatiBus);
                                                        $('#selezione').html(msg.actualSelection);
                                                        selezione = unescape(msg.actualSelection);
                                                        var openPins = msg.popupOpen;
                                                        if (textToSearch != "" && textToSearch != null) {
                                                            var nRes = msg.numeroRisultatiServizi;
                                                            if ((msg.actualSelection == "null" || msg.actualSelection == "") && (msg.categorie == "null" || msg.categorie == "") && (msg.coordinateSelezione == "null" || msg.coordinateSelezione == "")) {
                                                                showResultsFreeSearch(textToSearch, nRes);
                                                            }
                                                            else {
                                                                var range = msg.raggioServizi;
                                                                stringaCategorie = msg.categorie;
                                                                stringaCategorie = unescape(stringaCategorie);
                                                                if (msg.actualSelection.indexOf("COMUNE di") != -1) {
                                                                    var selection = msg.nomeComune;
                                                                    var startingPoint = "municipality";
                                                                }
                                                                else {
                                                                    var selection = msg.coordinateSelezione;
                                                                    var startingPoint = "point";
                                                                }
                                                                $("#loading").show();
                                                                svuotaLayers();
                                                                $.ajax({
                                                                    data: {
                                                                        search: textToSearch,
                                                                        results: nRes,
                                                                        range: range,
                                                                        selection: selection,
                                                                        startingPoint: startingPoint,
                                                                        categorie: stringaCategorie
                                                                    },
                                                                    url: ctx + "/ajax/json/get-services-by-text.jsp",
                                                                    type: "GET",
                                                                    dataType: 'json',
                                                                    async: true,
                                                                    success: function (data) {
                                                                        if (data.features.length > 0) {
                                                                            servicesLayer = L.geoJson(data, {
                                                                                pointToLayer: function (feature, latlng) {
                                                                                    marker = showmarker(feature, latlng);
                                                                                    return marker;
                                                                                },
                                                                                onEachFeature: function (feature, layer) {
                                                                                    popupContent = "";
                                                                                    var divId = feature.id + "-" + feature.properties.tipo;
                                                                                    popupContent = popupContent + "<div id=\"" + divId + "\" ></div>";
                                                                                    layer.bindPopup(popupContent);
                                                                                }
                                                                            }).addTo(map);
                                                                            if (mode == "embed") {
                                                                                for (i in servicesLayer._layers) {
                                                                                    var uri = servicesLayer._layers[i].feature.properties.serviceUri;
                                                                                    if (include(openPins, uri))
                                                                                        servicesLayer._layers[i].openPopup();
                                                                                }
                                                                            }
                                                                            var confiniMappa = servicesLayer.getBounds();
                                                                            map.fitBounds(confiniMappa, {padding: [50, 50]});
                                                                            $('#loading').hide();
                                                                        }
                                                                        else {
                                                                            $('#loading').hide();
                                                                            risultatiRicerca(0, 0, 0, 1);
                                                                        }
                                                                    },
                                                                    error: function (request, status, error) {
                                                                        $('#loading').hide();
                                                                        console.log(error);
                                                                        alert('Error in searching ' + text + "\n The error is " + error);
                                                                    }
                                                                });
                                                            }
                                                        }
                                                        else if (categorie != "null") { //no text search
                                                            var categorieArray = categorie.split(",");
                                                            var stringaCategorie = categorieArray.join(";");
                                                            stringaCategorie = stringaCategorie.replace("[", "");
                                                            stringaCategorie = stringaCategorie.replace("]", "");
                                                            stringaCategorie = stringaCategorie.replace(/\s+/g, '');
                                                            coordinateSelezione = unescape(msg.coordinateSelezione);
                                                            //$("#embed").show();
                                                            mostraServiziAJAX_new(stringaCategorie, msg.actualSelection, coordinateSelezione, msg.nomeComune, msg.numeroRisultatiServizi, msg.numeroRisultatiSensori, msg.numeroRisultatiBus, msg.raggioServizi, msg.raggioSensori, msg.raggioBus, openPins, null, "categorie");
                                                        }
                                                        else {
                                                        }
                                                    }
                                                });
                                            }
                                        }
                                    }
                                    function showResultsFreeSearch(textToSearch, limit) {
                                        textToSearch = escape(textToSearch);
                                        $('#loading').show();
                                        $.ajax({
                                            data: {
                                                search: textToSearch,
                                                limit: limit
                                            },
                                            url: ctx + "/ajax/json/free-text-search.jsp",
                                            type: "GET",
                                            dataType: 'json',
                                            async: true,
                                            success: function (data) {
                                                if (data.features.length > 0) {
                                                    servicesLayer = L.geoJson(data, {
                                                        pointToLayer: function (feature, latlng) {
                                                            marker = showmarker(feature, latlng);
                                                            return marker;
                                                        },
                                                        onEachFeature: function (feature, layer) {
                                                            popupContent = "";
                                                            var divId = feature.id + "-" + feature.properties.tipo;
                                                            popupContent = popupContent + "<div id=\"" + divId + "\" ></div>";
                                                            layer.bindPopup(popupContent);
                                                        }
                                                    }).addTo(map);
                                                    if (mode == "embed") {
                                                        for (i in servicesLayer._layers) {
                                                            var uri = servicesLayer._layers[i].feature.properties.serviceUri;
                                                            if (include(openPins, uri))
                                                                servicesLayer._layers[i].openPopup();
                                                        }
                                                    }
                                                    var confiniMappa = servicesLayer.getBounds();
                                                    map.fitBounds(confiniMappa, {padding: [50, 50]});
                                                    $('#loading').hide();
                                                }
                                                else {
                                                    $('#loading').hide();
                                                    risultatiRicerca(0, 0, 0, 1);
                                                }
                                            },
                                            error: function (request, status, error) {
                                                $('#loading').hide();
                                                console.log(error);
                                                alert('Error in searching ' + text + "\n The error is " + error);
                                            }
                                        });
                                    }

                                    function showService(serviceUri) {
                                        $('#loading').show();
                                        $.ajax({
                                            data: {
                                                serviceUri: serviceUri
                                            },
                                            url: ctx + "/api/service.jsp",
                                            type: "GET",
                                            async: true,
                                            dataType: 'json',
                                            success: function (msg) {
                                                if (msg != null && msg.meteo != null) {
                                                    $.ajax({
                                                        url: "${pageContext.request.contextPath}/ajax/get-weather.jsp",
                                                        type: "GET",
                                                        async: true,
                                                        data: {
                                                            nomeComune: msg.meteo.location
                                                        },
                                                        success: function (msgMeteo) {
                                                            $('#info-aggiuntive .content').html(msgMeteo);
                                                            $('#loading').hide();
                                                        }
                                                    });
                                                } else if (msg != null && msg.features.length > 0 && msg.features[0].geometry.coordinates != undefined) {
                                                    var longService = msg.features[0].geometry.coordinates[0];
                                                    var latService = msg.features[0].geometry.coordinates[1];
                                                    servicesLayer = L.geoJson(msg, {
                                                        pointToLayer: function (feature, latlng) {
                                                            marker = showmarker(feature, latlng);
                                                            return marker;
                                                        },
                                                        onEachFeature: function (feature, layer) {
                                                            var tipo = feature.properties.tipo;
                                                            var divMM = feature.id + "-multimedia";
                                                            var multimediaResource = feature.properties.multimedia;
                                                            var htmlDiv;
                                                            if (multimediaResource != null)
                                                            {
                                                                var format = multimediaResource.substring(multimediaResource.length - 4);
                                                                if (format == ".mp3") {
                                                                    htmlDiv = "<div id=\"" + divMM + "\"class=\"multimedia\"><audio controls class=\"audio-controls\"><source src=\"" + multimediaResource + "\" type=\"audio/mpeg\"></audio></div>";
                                                                } else {
                                                                    if ((format == ".wav") || (format == ".ogg")) {
                                                                        htmlDiv = "<div id=\"" + divMM + "\"class=\"multimedia\"><audio controls class=\"audio-controls\"><source src=\"" + multimediaResource + "\" type=\"audio/" + format + "\"></audio></div>";
                                                                    } else {
                                                                        htmlDiv = "<div id=\"" + divMM + "\"class=\"multimedia\"><img src=\"" + multimediaResource + "\" width=\"80\" height=\"80\"></div>";
                                                                    }
                                                                }
                                                            }
                                                            if (include(tipo, "@en"))
                                                                tipo = tipo.replace("@en", "");
                                                            else
                                                                tipo = tipo.replace("@it", "");
                                                            var divId = feature.id + "-" + tipo;
                                                            if (feature.properties.tipo != "fermata") {
                                                                contenutoPopup = createContenutoPopup(feature, divId, feature.id);
                                                                layer.addTo(map).bindPopup(contenutoPopup).openPopup();
                                                                if (feature.multimedia != null) {
                                                                    //$(".leaflet-popup-content-wrapper").css("width", "300px"); 
                                                                    $('#' + divId).closest('div.leaflet-popup-content-wrapper').css("width", "300px");
                                                                }
                                                                popup_fixpos(divId);
                                                            }
                                                            else {
                                                                var contenutoPopup = createContenutoPopup(feature, divId, feature.id);
                                                                layer.addTo(map).bindPopup(contenutoPopup).openPopup();
                                                            }
                                                        }
                                                    });
                                                    map.setView(new L.LatLng(latService, longService), 16);
                                                }
                                                else {
                                                    alert("no info found for service " + serviceUri);
                                                }
                                                $('#loading').hide();
                                            }
                                        });
                                    }

                                    function showEmbedConfiguration(parameters) {
                                        var idConfiguration = parameters['idConf'];
                                        //var scale=parameters['scale'];
                                        //var translate=parameters['translate'];
                                        $.ajax({
                                            data: {
                                                idConfiguration: idConfiguration,
                                                scale: scale,
                                                translate: translate
                                            },
                                            url: "api/embed/configuration.jsp",
                                            type: "GET",
                                            async: true,
                                            dataType: 'json',
                                            success: function (msg) {
                                                if (msg.nomeProvincia != null) {
                                                    $("#elencoprovince").val(msg.nomeProvincia);
                                                    mostraElencoComuni(msg.nomeProvincia, msg.nomeComune);
                                                    $("#ui-id-2").click();
                                                }
                                                if (msg.line != null) {
                                                    getBusLines("embed");
                                                    $("#elencolinee").val(msg.line);
                                                    mostraElencoFermate(msg.line, msg.stop);
                                                    $("#ui-id-1").click();
                                                }
                                                if (msg.pins)
                                                    var pins = JSON.parse(msg.pins);
                                                if (msg.popupOpen)
                                                    var openPopup = JSON.parse(msg.popupOpen);
                                                $("#raggioricerca").val(msg.radius);
                                                $("#numerorisultati").val(msg.numeroRisultati);
                                                $('#selezione').html(msg.actualSelection);
                                                var center = JSON.parse(msg.center);
                                                map.setView(new L.LatLng(center.lat, center.lng), msg.zoom);
                                                var openPins = [];
                                                for (var i = 0; i < openPopup.length; i++) {
                                                    openPins.push(openPopup[i].id);
                                                }
                                                var weatherCity = msg.weatherCity;
                                                if (weatherCity) {
                                                    $.ajax({
                                                        url: "${pageContext.request.contextPath}/ajax/get-weather.jsp",
                                                        type: "GET",
                                                        async: true,
                                                        data: {
                                                            nomeComune: weatherCity
                                                        },
                                                        success: function (msg) {
                                                            $('#info-aggiuntive .content').html(msg);
                                                        }
                                                    });
                                                }
                                                var categorie = msg.categorie;
                                                //categorie=categorie.substr(1,categorie.length-1);
                                                $("#categorie :not(:checked)").each(function () {
                                                    var category = $(this).val();
                                                    if (categorie.indexOf(category) > -1)
                                                        $(this).attr("checked", true);
                                                });
                                                servicesLayer = L.geoJson(pins, {
                                                    pointToLayer: function (feature, latlng) {
                                                        marker = showmarker(feature, latlng);
                                                        return marker;
                                                    },
                                                    onEachFeature: function (feature, layer) {

                                                        var divId = feature.id + "-" + feature.properties.tipo;
                                                        if (feature.properties.tipo != "fermata") {
                                                            contenutoPopup = "<h3>" + feature.properties.nome + "</h3>";
                                                            contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + feature.properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                                            contenutoPopup = contenutoPopup + "Tipologia: " + feature.properties.tipo + "<br />";
                                                            if (feature.properties.email != "" && feature.properties.email)
                                                                contenutoPopup = contenutoPopup + "Email: " + feature.properties.email + "<br />";
                                                            if (feature.properties.indirizzo != "")
                                                                contenutoPopup = contenutoPopup + "Indirizzo: " + feature.properties.indirizzo;
                                                            if (feature.properties.numero != "" && feature.properties.numero)
                                                                contenutoPopup = contenutoPopup + ", " + feature.properties.numero + "<br />";
                                                            else
                                                                contenutoPopup = contenutoPopup + "<br />";
                                                            if (feature.properties.note != "" && feature.properties.note)
                                                                contenutoPopup = contenutoPopup + "Note: " + feature.properties.note + "<br />";
                                                            contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                                            if (include(openPins, feature.id))
                                                                layer.addTo(map).bindPopup(contenutoPopup).openPopup();
                                                            else
                                                                layer.addTo(map).bindPopup(contenutoPopup);
                                                        }
                                                        else {
                                                            var divLinee = divId + "-linee";
                                                            var contenutoPopup = "<h3>FERMATA : " + feature.properties.popupContent + "</h3>";
                                                            contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + feature.properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                                            contenutoPopup += "<div id=\"" + divLinee + "\" ></div>";
                                                            contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                                            if (include(openPins, feature.id))
                                                                layer.addTo(map).bindPopup(contenutoPopup).openPopup();
                                                            else
                                                                layer.addTo(map).bindPopup(contenutoPopup);
                                                        }
                                                    }
                                                });
                                                $("#loading").hide();
                                            }
                                        });
                                    }

                                    /***  codice per mantenere aperto pi� di un popup per volta ***/
                                    L.Map = L.Map.extend({
                                        openPopup: function (popup) {
                                            //        this.closePopup();  // just comment this
                                            this._popup = popup;
                                            return this.addLayer(popup);
                                        }

                                    });
                                    // CREAZIONE MAPPA CENTRATA NEL PUNTO
                                    //commentato marco
                                    //var map = L.map('map').setView([43.3555664, 11.0290384], 8);

                                    // SCELTA DEL TILE LAYER ED IMPOSTAZIONE DEI PARAMETRI DI DEFAULT
                                    /*commentato marco
                                     L.tileLayer('http://c.tiles.mapbox.com/v3/examples.map-szwdot65/{z}/{x}/{y}.png', { // NON MALE
                                     //L.tileLayer('http://{s}.tile.cloudmade.com/{key}/22677/256/{z}/{x}/{y}.png', {
                                     //L.tileLayer('http://a.www.toolserver.org/tiles/bw-mapnik/{z}/{x}/{y}.png', {
                                     //L.tileLayer('http://a.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                                     //L.tileLayer('http://tilesworld1.waze.com/tiles/{z}/{x}/{y}.png', {
                                     //		L.tileLayer('http://maps.yimg.com/hx/tl?v=4.4&x={x}&y={y}&z={z}', {
                                     //L.tileLayer('http://a.tiles.mapbox.com/v3/examples.map-bestlap85.h67h4hc2/{z}/{x}/{y}.png', { MAPBOX MA NON FUNZIA
                                     //L.tileLayer('http://{s}.tile.cloudmade.com/1a1b06b230af4efdbb989ea99e9841af/998/256/{z}/{x}/{y}.png', { 
                                     //	L.tileLayer('http://{s}.tile.cloudmade.com/1a1b06b230af4efdbb989ea99e9841af/121900/256/{z}/{x}/{y}.png', { 
                                     attribution: 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2012 CloudMade',
                                     key: 'BC9A493B41014CAABB98F0471D759707',
                                     minZoom: 8
                                     }).addTo(map);
                                     
                                     *fine commento marco
                                     */

                                    //codice per gestione layers
                                    //var osm = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'});
                                    //http://otile1.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg
                                    //http://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png
                                    //http://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png
                                    //http://a.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png
                                    //http://a.tile.stamen.com/toner/{z}/{x}/{y}.png
                                    //http://a.tile.thunderforest.com/landscape/{z}/{x}/{y}.png
                                    //var osm = L.tileLayer('http://a.tile.thunderforest.com/landscape/{z}/{x}/{y}.png', {attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'});

                                    var mbAttr = 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
                                            '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
                                            'Imagery � <a href="http://mapbox.com">Mapbox</a>',
                                            mbUrl = 'https://{s}.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=<%=mapAccessToken%>';
                                    var streets = L.tileLayer(mbUrl, {id: 'mapbox.streets', attribution: mbAttr}),
                                            satellite = L.tileLayer(mbUrl, {id: 'mapbox.streets-satellite', attribution: mbAttr}),
                                            grayscale = L.tileLayer(mbUrl, {id: 'pbellini.f33fdbb7', attribution: mbAttr});
                                    var map = L.map('map', {
                                        center: [43.3555664, 11.0290384],
                                        zoom: 8,
                                        layers: [satellite]
                                    });
                                    var baseMaps = {
                                        "Streets": streets,
                                        "Satellite": satellite,
                                        "Grayscale": grayscale
                                    };
                                    var toggleMap = L.control.layers(baseMaps, null, {position: 'bottomright', width: '50px', height: '50px'});
                                    toggleMap.addTo(map);
                                    if (getUrlParameter("map") == "streets") {
                                        map.removeLayer(satellite);
                                        map.addLayer(streets);
                                    }
                                    else if (getUrlParameter("map") == "grayscale") {
                                        map.removeLayer(satellite);
                                        map.addLayer(grayscale);
                                    }

                                    // DEFINIZIONE DEI CONFINI MASSIMI DELLA MAPPA
                                    var bounds = new L.LatLngBounds(new L.LatLng(41.7, 8.4), new L.LatLng(44.930222, 13.4));
                                    map.setMaxBounds(bounds);
                                    // GENERAZIONE DEI LAYER PRINCIPALI
                                    var busStopsLayer = new L.LayerGroup();
                                    var servicesLayer = new L.LayerGroup();
                                    var eventLayer = new L.LayerGroup();
                                    var clickLayer = new L.LayerGroup();
                                    var GPSLayer = new L.LayerGroup();
                                    // AGGIUNTA DEL PLUGIN PER LA GEOLOCALIZZAZIONE
                                    var GPSControl = new L.Control.Gps({
                                        maxZoom: 16,
                                        style: null
                                    });
                                    map.addControl(GPSControl);
                                    //$("#currentPosition").add(GPSControl);+

                                    // ASSOCIA FUNZIONI AGGIUNTIVE ALL'APERTURA DI UN POPUP SU PARTICOLARI TIPI DI DATI
                                    var last_marker = null;
                                    map.on('popupopen', function (e) {


                                        $('#raggioricerca').prop('disabled', false);
                                        $('#raggioricerca_t').prop('disabled', false);
                                        $('#PublicTransportLine').prop('disabled', false);
                                        $('#nResultsServizi').prop('disabled', false);
                                        $('#nResultsSensori').prop('disabled', false);
                                        $('#nResultsBus').prop('disabled', false);
                                        $('#approximativeAddress').html('');
                                        var markerPopup = e.popup._source;
                                        //aggiunto
                                        var idServizio = markerPopup.feature.id;
                                        currentServiceUri = markerPopup.feature.properties.serviceUri;
                                        var tipoServizio = markerPopup.feature.properties.tipo;
                                        var serviceType = markerPopup.feature.properties.serviceType;
                                        var nome = markerPopup.feature.properties.nome;
                                        var divId = idServizio + "-" + markerPopup.feature.properties.tipo;
                                        var coordinates = markerPopup.feature.geometry.coordinates;
                                        if (markerPopup.feature.properties.multimedia != "" && markerPopup.feature.properties.multimedia != null) {
                                            $('#' + divId).closest('div.leaflet-popup-content-wrapper').css("width", "300px");
                                        }
                                        popup_fixpos(divId);
                                        if (mode != "embed") {
                                            //selezione = 'Servizio: ' + markerPopup.feature.properties.nome;
                                            if (tipoServizio == 'fermata'){
                                                selezione = 'Bus Stop: ' + markerPopup.feature.properties.nome;
                                            }else{
                                                selezione = 'Service: ' + markerPopup.feature.properties.nome;
                                            }
                                            $('#selezione').html(selezione);
                                            clickLayer.clearLayers();
                                            // CLICK SUL MARKER - Viene evidenziato il SELECTED marker, e settata l'icona di default al precedente selezionato.                                
                                            $(markerPopup._icon).siblings().removeClass('selected');
                                            if (last_marker != null && last_marker.getLatLng() != markerPopup.getLatLng()) {
                                                if (last_marker.feature.properties.serviceType == "") {
                                                    var serviceIcon = "generic";
                                                } else {
                                                    var serviceIcon = last_marker.feature.properties.serviceType;
                                                }
                                                if (last_marker.feature.properties.serviceType != "bus_real_time") {
                                                    var def_icon = L.icon({
                                                        //iconUrl: ctx + '/img/mapicons/' + last_marker.feature.properties.serviceType + '.png',
                                                        //iconRetinaUrl: ctx + '/img/mapicons/' + last_marker.feature.properties.serviceType + '.png',
                                                        iconUrl: ctx + '/img/mapicons/' + serviceIcon + '.png',
                                                        iconRetinaUrl: ctx + '/img/mapicons/' + serviceIcon + '.png',
                                                        iconSize: [26, 29],
                                                        iconAnchor: [13, 29], });
                                                    //popupAnchor: [0, -27],});
                                                    last_marker.setIcon(def_icon);
                                                }
                                                else {
                                                    var def_icon = L.icon({
                                                        iconUrl: ctx + '/img/mapicons/' + serviceIcon + '.gif',
                                                        iconRetinaUrl: ctx + '/img/mapicons/' + serviceIcon + '.gif',
                                                        iconSize: [15, 15],
                                                        iconAnchor: [7, 15],
                                                        popupAnchor: [0, -7], });
                                                    last_marker.setIcon(def_icon);
                                                }
                                            }
                                            $(markerPopup._icon).addClass('selected');
                                            last_marker = markerPopup;
                                        }
                                        /*if ((tipoServizio != 'fermata')||(tipoServizio != 'parcheggio_auto')||(tipoServizio != 'parcheggio_Coperto')||(tipoServizio != "parcheggio_all'aperto")||(tipoServizio != 'car_park@en')||(tipoServizio != 'sensore')) {
                                         //showService(currentServiceUri);
                                         loadServiceInfo(currentServiceUri, divId);
                                         
                                         }*/

                                        //if ((mode != "query") && (mode != "embed")) {
                                        loadServiceInfo(currentServiceUri, divId, idServizio, coordinates);
                                        //}
                                        coordinateSelezione = markerPopup.feature.geometry.coordinates[1] + ";" + markerPopup.feature.geometry.coordinates[0];
                                        /*if (tipoServizio == 'fermata') {
                                         selezione = 'Fermata Bus: ' + markerPopup.feature.properties.nome;
                                         coordinateSelezione = markerPopup.feature.geometry.coordinates[1] + ";" + markerPopup.feature.geometry.coordinates[0];
                                         $('#selezione').html(selezione);
                                         var divLinee = divId + "-linee";
                                         mostraAVMAJAX(nome, divId);
                                         mostraLineeBusAJAX(nome, divLinee);
                                         }
                                         if (tipoServizio == 'parcheggio_auto' || tipoServizio == "parcheggio_Coperto" || tipoServizio == "parcheggi_all'aperto" || tipoServizio == "car_park@en") {
                                         mostraParcheggioAJAX(nome, divId);
                                         }
                                         
                                         if (tipoServizio == 'sensore') {
                                         mostraSensoreAJAX(nome, divId);
                                         }
                                         // var stringJsonPopUp=JSON.stringify(markerPopup);*/
                                        listOfPopUpOpen.push(currentServiceUri);
                                    });
                                    map.on('popupclose', function (e) {
                                        var popupToRemove = e.popup._source;
                                        for (var i = listOfPopUpOpen.length - 1; i >= 0; i--) {
                                            if (listOfPopUpOpen[i] === popupToRemove.feature.properties.serviceUri) {
                                                listOfPopUpOpen.splice(i, 1);
                                            }
                                        }
                                    });
                                    // AL CLICK CERCO L'INDIRIZZO APPROSSIMATIVO	
                                    map.on('click', function (e) {
                                        listOfPopUpOpen = [];
                                        if (/*selezioneAttiva == */true) {
                                            if (ricercaInCorso == false) {
                                                $('#raggioricerca').prop('disabled', false);
                                                $('#raggioricerca_t').prop('disabled', false);
                                                $('#PublicTransportLine').prop('disabled', false);
                                                $('#nResultsServizi').prop('disabled', false);
                                                $('#nResultsSensori').prop('disabled', false);
                                                $('#nResultsBus').prop('disabled', false);
                                                ricercaInCorso = true;
                                                $('#approximativeAddress').html("Address: <img src=\"img/ajax-loader.gif\" width=\"16\" />");
                                                clickLayer.clearLayers();
                                                //clickLayer = new L.LatLng(e.latlng);
                                                clickLayer = L.layerGroup([new L.marker(e.latlng)]).addTo(map);
                                                var latLngPunto = e.latlng;
                                                coordinateSelezione = latLngPunto.lat + ";" + latLngPunto.lng;
                                                var latPunto = new String(latLngPunto.lat);
                                                var lngPunto = new String(latLngPunto.lng);
                                                selezione = 'Coord: ' + latPunto.substring(0, 7) + "," + lngPunto.substring(0, 7);
                                                $('#selezione').html(selezione);
                                                $.ajax({
                                                    url: "${pageContext.request.contextPath}/ajax/get-address.jsp",
                                                    type: "GET",
                                                    async: true,
                                                    //dataType: 'json',
                                                    data: {
                                                        lat: latPunto,
                                                        lng: lngPunto
                                                    },
                                                    success: function (msg) {
                                                        $('#approximativeAddress').html(msg);
                                                        ricercaInCorso = false;
                                                    }
                                                });
                                            }
                                        }
                                    });
                                    var selezioneAttiva = false;
                                    var ricercaInCorso = false;
                                    var logEndPoint = "<%=logEndPoint%>";
                                    $(document).ready(function () {
                                        // funzione di inizializzazione all'avvio della mappa
                                        init();
                                    });
                                    function init() {
                                        // CREO LE TABS JQUERY UI NEL MENU IN ALTO
                                        $("#tabs").tabs();
                                        $("#tabs-servizi").tabs();
                                        if (mode == "query" || mode == "embed") {
                                            var url = document.URL;
                                            var queryString = url.substring(url.indexOf('?') + 1);
                                            var parameters = parseUrlQuery(queryString);
                                            $("#embed.menu").hide();
                                            $("#save").hide();
                                            $("#saveQuery").hide();
                                            $("#saveQuerySearch").hide();
                                            var controls = parameters["controls"];
                                            if (mode == "query" && controls == undefined)
                                                controls = "collapsed";
                                            if (controls == "false" || controls == "hidden" || controls == undefined) {
                                                $("#menu-dx").hide();
                                                $("#menu-alto").hide();
                                                $("#embed.menu").hide();
                                            }
                                            else if (controls == "collapsed") {
                                                $("#menu-dx .header").click();
                                                $("#menu-alto .header").click();
                                            }
                                            var info = parameters["info"];
                                            if (info == "false" || info == "hidden") {
                                                $("#info-aggiuntive").hide();
                                            }
                                            else if (info == "collapsed") {
                                                $("#info-aggiuntive .header").click();
                                            }
                                            if (parameters["description"] == "false") {
                                                $("#queryBox").hide();
                                            }
                                            if (parameters["showBusPosition"] == "true") {
                                                mostraAutobusRT(true);
                                            }
                                            else
                                                showResults(parameters);
                                        }
                                    }

                                    var comuneChoice;
                                    var selezione;
                                    var coordinateSelezione;
                                    var numeroRisultati;
                                    // MOSTRA ELENCO COMUNI DI UNA PROVINCIA
                                    function mostraElencoComuni(selectOption, nomeComune) {
                                        if ($("#elencoprovince").val() != null) {
                                            //	if (selectOption.options.selectedIndex != 0){	
                                            $('#elencolinee')[0].options.selectedIndex = 0;
                                            $('#elencofermate').html('<option value=""> - Select a Bus Stop - </option>');
                                            //$('#loading').show();
                                            $.ajax({
                                                url: "${pageContext.request.contextPath}/ajax/get-municipality-list.jsp",
                                                type: "GET",
                                                async: true,
                                                //dataType: 'json',
                                                data: {
                                                    nomeProvincia: $("#elencoprovince").val()
                                                            // nomeProvincia: selectOption.options[selectOption.options.selectedIndex].value
                                                },
                                                success: function (msg) {
                                                    $('#elencocomuni').html(msg);
                                                    if (mode == "embed" || mode == "query") {
                                                        $('#elencocomuni').val(nomeComune);
                                                        //$('#loading').hide();
                                                    }
                                                    else
                                                        $('#loading').hide();
                                                }
                                            });
                                        }
                                    }

                                    /*function loadServiceInfo(uri, div) {
                                     $.ajax({
                                     data: {
                                     serviceUri: uri
                                     },
                                     url: "${pageContext.request.contextPath}/api/service.jsp",
                                     type: "GET",
                                     async: true,
                                     dataType: 'json',
                                     success: function (data) {
                                     if (data.features.length > 0) {
                                     var tipo = data.features[0].properties.tipo;
                                     selezione = 'Servizio: ' + data.features[0].properties.nome;
                                     $('#selezione').html(selezione);
                                     var divMM = data.features[0].id + "-multimedia";
                                     var multimediaResource = data.features[0].properties.multimedia;
                                     var htmlDiv;
                                     if (multimediaResource != null)
                                     {
                                     var format = multimediaResource.substring(multimediaResource.length -4);
                                     if (format == ".mp3"){
                                     htmlDiv = "<div id=\"" + divMM + "\"class=\"multimedia\"><audio controls class=\"audio-controls\"><source src=\""+ multimediaResource +"\" type=\"audio/mpeg\"></audio></div>";
                                     }else{
                                     if ((format == ".wav") || (format == ".ogg")){
                                     htmlDiv = "<div id=\"" + divMM + "\"class=\"multimedia\"><audio controls class=\"audio-controls\"><source src=\""+ multimediaResource +"\" type=\"audio/"+ format+"\"></audio></div>";  
                                     }else{
                                     htmlDiv = "<div id=\"" + divMM + "\"class=\"multimedia\"><img src=\"" + multimediaResource + "\" width=\"80\" height=\"80\"></div>";   
                                     }
                                     }
                                     }
                                     if (include(tipo, "@en"))
                                     tipo = tipo.replace("@en", "");
                                     else
                                     tipo = tipo.replace("@it", "");
                                     var divId = data.features[0].id + "-" + tipo;
                                     if (data.features[0].properties.tipo != "fermata") {
                                     contenutoPopup = "<h3>" + data.features[0].properties.nome + "</h3>";
                                     contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + data.features[0].properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                     contenutoPopup = contenutoPopup + "<b>Tipologia:</b> " + tipo + "<br />";
                                     var feature = data.features[0];
                                     if (data.features[0].properties.email != "" && data.features[0].properties.email)
                                     contenutoPopup = contenutoPopup + "<b>Email:</b><a href=\"mailto:"+feature.properties.email+"?Subject=information request\" target=\"_top\"> " + feature.properties.email + "</a><br />";
                                     
                                     if (feature.properties.website != "" && feature.properties.website)
                                     contenutoPopup = contenutoPopup + "<b>Website:</b><a href=\"http\://"+ feature.properties.website + "\" target=\"_blank\" title=\""+feature.properties.nome+" - website\"> " + feature.properties.website + "</a><br />";
                                     if (feature.properties.phone != "" && feature.properties.phone)
                                     contenutoPopup = contenutoPopup + "<b>Phone:</b> " + feature.properties.phone + "<br />";
                                     if (feature.properties.fax != "" && feature.properties.fax)
                                     contenutoPopup = contenutoPopup + "<b>Fax:</b> " + feature.properties.fax + "<br />";
                                     if (data.features[0].properties.indirizzo != "")
                                     contenutoPopup = contenutoPopup + "<b>Indirizzo:</b> " + data.features[0].properties.indirizzo;
                                     if (data.features[0].properties.numero != "" && data.features[0].properties.numero)
                                     contenutoPopup = contenutoPopup + ", " + data.features[0].properties.numero + "<br />";
                                     else
                                     contenutoPopup = contenutoPopup + "<br />";
                                     if (feature.properties.cap != "" && feature.properties.cap)
                                     contenutoPopup = contenutoPopup + "<b>Cap:</b> " + feature.properties.cap + "<br />";
                                     if (feature.properties.city != "" && feature.properties.city)
                                     contenutoPopup = contenutoPopup + "<b>City:</b> " + feature.properties.city + "<br />";
                                     if (feature.properties.province != "" && feature.properties.province)
                                     contenutoPopup = contenutoPopup + "<b>Prov.:</b> " + feature.properties.province + "<br />";
                                     if (data.features[0].properties.multimedia != "" && data.features[0].properties.multimedia) {
                                     contenutoPopup = contenutoPopup + "<b>Multimedia Content:</b></br>" +htmlDiv;
                                     }
                                     if (data.features[0].properties.description != "" && data.features[0].properties.description) {
                                     if (include(data.features[0].properties.description, "@it"))
                                     data.features[0].properties.description = data.features[0].properties.description.replace("@it", "");
                                     contenutoPopup = contenutoPopup + "Description: " + data.features[0].properties.description + "<br />";
                                     }
                                     if (data.features[0].properties.note != "" && data.features[0].properties.note)
                                     contenutoPopup = contenutoPopup + "<b>Note:</b> " + data.features[0].properties.note + "<br />";
                                     
                                     contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                     var name = data.features[0].properties.nome;
                                     nameEscaped = escape(name);
                                     var divSavePin = "savePin-" + data.features[0].id;
                                     contenutoPopup = contenutoPopup + "<div id=\"" + divSavePin + "\" class=\"savePin\" onclick=save_handler('" + data.features[0].properties.tipo + "','" + data.features[0].properties.serviceUri + "','" + nameEscaped + "')></div>";
                                     //layer.addTo(map).bindPopup(contenutoPopup).openPopup();
                                     if (tipo == 'parcheggio_auto' || tipo == "parcheggio_Coperto" || tipo == "parcheggi_all'aperto" || tipo == "car_park@en") {
                                     mostraParcheggioAJAX(name, divId);
                                     }
                                     if (tipo == 'sensore') {
                                     mostraSensoreAJAX(name, divId);
                                     }
                                     $("#" + div).html(contenutoPopup);
                                     if (multimediaResource != "" && multimediaResource != null)
                                     $(".leaflet-popup-content-wrapper").css("width", "300px");
                                     popup_fixpos(div);
                                     } else {
                                     var divLinee = divId + "-linee";
                                     var contenutoPopup = "<h3>FERMATA : " + data.features[0].properties.nome + "</h3>";
                                     contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + data.features[0].properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                     contenutoPopup = contenutoPopup + "<div id=\"" + divLinee + "\" ></div>";
                                     contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                     var divSavePin = "savePin-" + data.features[0].id;
                                     var name = data.features[0].properties.nome;
                                     nameEscaped = escape(name);
                                     contenutoPopup = contenutoPopup + "<div id=\"" + divSavePin + "\" class=\"savePin\" onclick=save_handler('" + data.features[0].properties.tipo + "','" + data.features[0].properties.serviceUri + "','" + nameEscaped + "')></div>";
                                     $("#" + div).html(contenutoPopup);
                                     popup_fixpos(div);
                                     mostraAVMAJAX(name, divId);
                                     mostraLineeBusAJAX(name, divLinee);
                                     }
                                     } else {
                                     contenutoPopup = "No info sul servizio " + uri;
                                     $("#" + div).html(contenutoPopup);
                                     popup_fixpos(div);
                                     }
                                     }
                                     });
                                     }*/
                                    // FUNZIONI DI RICERCA PRINCIPALI
                                    function mostraLineeBusAJAX(nomeFermata, divLinee, divRoute) {
                                        $.ajax({
                                            url: "${pageContext.request.contextPath}/ajax/get-lines-of-stop.jsp",
                                            type: "GET",
                                            async: true,
                                            //dataType: 'json',
                                            data: {
                                                nomeFermata: nomeFermata,
                                                divRoute: divRoute,
                                            },
                                            success: function (msg) {
                                                $("#" + divLinee).html(msg);
                                                popup_fixpos(divLinee);
                                                //$('#info-aggiuntive .content').html(msg);
                                            }
                                        });
                                    }
                                    function mostraAVMAJAX(nomeFermata, divId) {
                                        $('#loading').show();
                                        $.ajax({
                                            url: "${pageContext.request.contextPath}/ajax/get-avm.jsp",
                                            type: "GET",
                                            async: true,
                                            //dataType: 'json',
                                            data: {
                                                nomeFermata: nomeFermata
                                            },
                                            success: function (msg) {
                                                $("#" + divId).html(msg);
                                                //$('#info-aggiuntive .content').html(msg);
                                                popup_fixpos(divId);
                                                $('#loading').hide();
                                            }
                                        });
                                    }
                                    function mostraParcheggioAJAX(nomeParcheggio, divId) {
                                        $.ajax({
                                            url: "${pageContext.request.contextPath}/ajax/get-parking-status.jsp",
                                            type: "GET",
                                            async: true,
                                            //dataType: 'json',
                                            data: {
                                                nomeParcheggio: nomeParcheggio
                                            },
                                            success: function (msg) {
                                                $("#" + divId).html(msg);
                                                //$('#info-aggiuntive .content').html(msg);
                                                popup_fixpos(divId);
                                            }
                                        });
                                    }
                                    function mostraSensoreAJAX(nomeSensore, divId) {
                                        $.ajax({
                                            url: "${pageContext.request.contextPath}/ajax/get-sensor-data.jsp",
                                            type: "GET",
                                            async: true,
                                            //dataType: 'json',
                                            data: {
                                                nomeSensore: nomeSensore
                                            },
                                            success: function (msg) {
                                                $("#" + divId).html(msg);
                                                popup_fixpos(divId);
                                                //$('#info-aggiuntive .content').html(msg);

                                            }
                                            // timeout:10000
                                        });
                                    }

                                    function updateSelection() {
                                        comuneChoice = $('#elencocomuni').val();
                                        selezione = "COMUNE di " + comuneChoice;
                                        $('#nResultsServizi').prop('disabled', false);
                                        $('#nResultsSensori').prop('disabled', false);
                                        $('#nResultsBus').prop('disabled', false);
                                        $('#selezione').html(selezione);
                                        coordinateSelezione = "";
                                        $('#raggioricerca')[0].options.selectedIndex = 0;
                                        $('#raggioricerca').prop('disabled', 'disabled');
                                        $('#raggioricerca_t')[0].options.selectedIndex = 0;
                                        $('#raggioricerca_t').prop('disabled', 'disabled');
                                        $('#approximativeAddress').html('');
                                        if ($('#PublicTransportLine').prop('checked')) {
                                            if ($('#PublicTransportLine').prop('checked', false))
                                                ;
                                        }
                                        $('#PublicTransportLine').prop('disabled', 'disabled');
                                        $.ajax({
                                            url: "${pageContext.request.contextPath}/ajax/get-weather.jsp",
                                            type: "GET",
                                            async: true,
                                            //dataType: 'json',
                                            data: {
                                                nomeComune: comuneChoice
                                            },
                                            success: function (msg) {
                                                $('#info-aggiuntive .content').html(msg);
                                            }
                                        });
                                    }

                                    function getCategorie(tipo_cat) {
                                        // ESTRAGGO LE CATEGORIE SELEZIONATE
                                        var categorie = [];
            <% if (km4cVersion.equals("old")) {%>
                                        $('#' + tipo_cat + ' :checked').each(function () {
                                            categorie.push($(this).val());
                                        });
            <%} else {%>
                                        var nCatAll = 0;
                                        $('#' + tipo_cat + ' .macrocategory:checked').each(function () {
                                            if ($('#' + tipo_cat + ' .sub_' + $(this).val() + ":not(:checked)").length == 0) {
                                                categorie.push($(this).val());
                                                if ($(this).val() == "TransferServiceAndRenting") {
                                                    categorie.push("BusStop");
                                                    categorie.push("SensorSite");
                                                }
                                                if ($(this).val() == "Path") {
                                                    categorie.pop("Path");
                                                    categorie.push("Cycle_paths");
                                                    categorie.push("Tourist_trail");
                                                    categorie.push("Tramline");
                                                }
                                                if ($(this).val() == "Area") {
                                                    categorie.pop("Area");
                                                    categorie.push("Gardens");
                                                    categorie.push("Green_areas");
                                                    categorie.push("Controlled_parking_zone");
                                                }
                                                // CODICE PER EVENTI NEI TRASVERSALI
                                                if ($(this).val() == "HappeningNow") {
                                                    categorie.pop("HappeningNow");
                                                    categorie.push("Event");
                                                }
                                                nCatAll++;
                                            }
                                            else
                                                $('#' + tipo_cat + ' .sub_' + $(this).val() + ":checked").each(function () {
                                                    categorie.push($(this).val());
                                                });
                                        });
                                        if (nCatAll == $('#' + tipo_cat + ' .macrocategory').length) {
                                            categorie = ["Service"];
                                            /*if (tipo_cat == "categorie") {
                                             categorie.push("BusStop");
                                             categorie.push("SensorSite");
                                             }else{
                                             
                                             if ($('#Bus').is(':checked'))
                                             categorie.push($("#Bus").val());
                                             if ($('#Sensor').is(':checked'))
                                             categorie.push($("#Sensor").val());
                                             }*/
                                            categorie.push("BusStop");
                                            categorie.push("SensorSite");
                                            if (tipo_cat == 'categorie_t') {
                                                categorie.push("Event");
                                                categorie.push("PublicTransportLine");
                                            }

                                        }
            <% }%>


                                        return categorie;
                                    }
                                    function ricercaServizi(tipo_categorie) {
                                        mode = "normal";
                                        var tipo_cat = tipo_categorie;
                                        var stringaCategorie = getCategorie(tipo_cat).join(";");
                                        if (selezione == undefined)
                                            selezione = "";
                                        if (tipo_categorie == "categorie")
                                            var raggioRicerca = $("#raggioricerca").val();
                                        else
                                            var raggioRicerca = $("#raggioricerca_t").val();
                                        if (((selezione != '') && (selezione.indexOf('Bus Line') == -1)) || raggioRicerca == "area") {
                                            if (stringaCategorie == "") {
                                                alert("Selezionate almeno una categoria nel menu di destra");
                                            }
                                            else {
                                                $('#loading').show();
                                                // SVUOTO LA MAPPA DAI PUNTI PRECEDENTEMENTE DISEGNATI
                                                if ((selezione.indexOf("Linea Bus:") == -1) || (selezione.indexOf("Bus Line:") == -1)) {
                                                    svuotaLayers();
                                                }
                                                mostraServiziAJAX_new(stringaCategorie, selezione, coordinateSelezione, comuneChoice, null, null, null, null, null, null, null, null, tipo_cat);
                                            }
                                        }
                                        else {
                                            //alert("Attenzione, non � stata selezionata alcuna risorsa di partenza per la ricerca");
                                            alert("Attention, you did not select any resources base for research");
                                        }
                                    }

                                    function mostraServiziAJAX_new(categorie, selezione, coordinateSelezione, nomeComune, risultatiServizi, risultatiSensori, risultatiBus, raggioServizi, raggioSensori, raggioBus, openPins, textFilter, tipo_categoria) {
                                        //$('#info-aggiuntive .content').html('');
                                        if (tipo_categoria == undefined)
                                            tipo_categoria = "categorie";
                                        if (mode != "query" && mode != "embed") {
                                            if (tipo_categoria == "categorie") {
                                                var numeroRisultatiServizi = $('#nResultsServizi').val();
                                                var numeroRisultatiSensori = $('#nResultsSensor').val();
                                                var numeroRisultatiBus = $('#nResultsBus').val();
                                                var raggioServizi = $("#raggioricerca").val();
                                                var raggioSensori = $("#raggioricerca").val();
                                                var raggioBus = $("#raggioricerca").val();
                                                var textFilter = $("#serviceTextFilter").val();
                                            }
                                            else {
                                                var numeroRisultatiServizi = $('#nResultsServizi_t').val();
                                                var raggioServizi = $("#raggioricerca_t").val();
                                                var textFilter = $("#serviceTextFilter_t").val();
                                            }

                                            //per salvataggio query
                                            var raggi = [];
                                            raggi.push(raggioServizi, raggioSensori, raggioBus);
                                            var numRis = [];
                                            numRis.push(numeroRisultatiServizi, numeroRisultatiSensori, numeroRisultatiBus);
                                        }
                                        else {
                                            //modificare per riprendere tutti i valori del numero risultati (servizi, sensori e bus)
                                            numeroRisultatiServizi = risultatiServizi;
                                            numeroRisultatiSensori = risultatiSensori;
                                            numeroRisultatiBus = risultatiBus;
                                            //modificare per riprendere tutti i valori dei raggi (servizi, sensori e bus)
                                            var raggioServizi = raggioServizi;
                                            var raggioSensori = raggioSensori;
                                            var raggioBus = raggioBus;
                                            $('#loading').show();
                                        }
                                        var centroRicerca;
                                        if (pins.length > 0)
                                            pins = "";
                                        if (((selezione != null && selezione.indexOf("COMUNE di") == -1) && raggioServizi == "area") || (coordinateSelezione != "" && undefined != coordinateSelezione && coordinateSelezione != "null" && coordinateSelezione != null)) {
                                            if (raggioServizi == "area") {
                                                var bnds = map.getBounds()
                                                centroRicerca = bnds.getSouth() + ";" + bnds.getWest() + ";" + bnds.getNorth() + ";" + bnds.getEast();
                                            }
                                            else if (coordinateSelezione == "Posizione Attuale") {
                                                // SE HO RICHIESTO LA POSIZIONE ATTUALE ESTRAGGO LE COORDINATE
                                                centroRicerca = GPSControl._currentLocation.lat + ";" + GPSControl._currentLocation.lng;
                                            }
                                            else if ((selezione.indexOf("Fermata Bus:") != -1) || (selezione.indexOf("Bus Stop:") != -1)) {
                                                centroRicerca = coordinateSelezione;
                                            }
                                            else if (selezione.indexOf("Coord:") != -1 || selezione.indexOf("Numero Bus:") != -1) {
                                                centroRicerca = coordinateSelezione;
                                            }
                                            else if ((selezione.indexOf("Servizio:") != -1) || (selezione.indexOf("Service:") != -1)) {
                                                centroRicerca = coordinateSelezione;
                                            }
                                            else if (selezione.indexOf("point") != -1) {
                                                centroRicerca = coordinateSelezione;
                                            }
                                            query = saveQueryServices(centroRicerca, raggi, categorie, numRis, selezione);
                                            var coord = centroRicerca.split(";");
                                            clickLayer.clearLayers();
                                            if (raggioServizi != "area") {
                                                clickLayer.addLayer(L.marker([coord[0], coord[1]]));
                                                /*clickLayer.addLayer(L.circle([coord[0], coord[1]], raggioServizi * 1000, {id: 'circle'})).addTo(map);*/
                                                clickLayer.addLayer(L.circle([coord[0], coord[1]], raggioServizi * 1000, {className: 'circle'})).addTo(map);
                                            }
                                            var numeroServizi = 0;
                                            var numeroBus = 0;
                                            var numeroSensori = 0;
                                            var numEventi = 0;
                                            var numLineeBus = 0;
                                            $.ajax({
                                                url: "${pageContext.request.contextPath}/ajax/json/get-services.jsp",
                                                type: "GET",
                                                async: true,
                                                dataType: 'json',
                                                data: {
                                                    centroRicerca: centroRicerca,
                                                    raggioServizi: raggioServizi,
                                                    raggioSensori: raggioSensori,
                                                    raggioBus: raggioBus,
                                                    categorie: categorie,
                                                    textFilter: textFilter,
                                                    numeroRisultatiServizi: numeroRisultatiServizi,
                                                    numeroRisultatiSensori: numeroRisultatiSensori,
                                                    cat_servizi: tipo_categoria,
                                                    numeroRisultatiBus: numeroRisultatiBus
                                                },
                                                success: function (msg) {
                                                    if (mode == "JSON") {
                                                        $("#body").html(JSON.stringify(msg));
                                                    }
                                                    else {
                                                        var array = new Array();
                                                        var delta = new Array();
                                                        var sin = new Array();
                                                        var cos = new Array();
                                                        var sx = new Array();
                                                        var dx = new Array();
                                                        var fract = 0.523599;
                                                        var dist = 1.2;
                                                        var passo = 0.00007;
                                                        
                                                        for (var r = 0; r < 10; r++) {
                                                            array[r] = new Array();
                                                            for (var c = 0; c < 2; c++) {
                                                                array[r][c] = 0;
                                                            }
                                                            delta[r] = 0;
                                                            sin[r] = 0;
                                                            cos[r] = 0;
                                                            sx[r] = 0;
                                                            dx[r] = 0;
                                                        }
                                                        var i = 0;
                                                        //	console.log(msg);
                                                        $('#loading').hide();
                                                        if (msg != null && msg.features.length > 0) {
                                                            var count = 0;
                                                            for (i = 0; i < msg.features.length; i++) {
                                                                if (msg.features[i].properties.serviceType == 'TourismService_Tourist_trail') {
                                                                    if (count == 0) {
                                                                        array[0][0] = msg.features[i].geometry.coordinates[0];
                                                                        array[0][1] = msg.features[i].geometry.coordinates[1];
                                                                    } else {
                                                                        for (var k = 0; k < count; k++) {
                                                                            if ((msg.features[i].geometry.coordinates[0] == array[k][0]) && (msg.features[i].geometry.coordinates[1] == array[k][1])) {
                                                                                
                                                                                delta[count] = (fract*count);
                                                                                sin[count] = Math.sin(delta[count]);
                                                                                cos[count] = Math.cos(delta[count]);
                                                                                sx[count] = (sin[count]*passo*dist*count);
                                                                                dx[count] = (cos[count]*passo*dist*count);;
                                                                                
                                                                                //array[count][0] = msg.features[i].geometry.coordinates[0] + (Math.random() - .4) / 1500;
                                                                                //array[count][1] = msg.features[i].geometry.coordinates[1] + (Math.random() - .4) / 1500;
                                                                                //msg.features[i].geometry.coordinates[0] = array[count][0];
                                                                                //msg.features[i].geometry.coordinates[1] = array[count][1];
                                                                                
                                                                                array[count][0] = (array[0][0])+sx[count];
                                                                                array[count][1] = (array[0][1])+dx[count];
                                                                                msg.features[i].geometry.coordinates[0] = array[count][0];
                                                                                msg.features[i].geometry.coordinates[1] = array[count][1];
                                                                            } else {
                                                                                array[count][0] = msg.features[i].geometry.coordinates[0];
                                                                                array[count][1] = msg.features[i].geometry.coordinates[1];
                                                                            }

                                                                        }

                                                                    }
                                                                    count++;
                                                                }

                                                            }
                                                            
                                                            servicesLayer = L.geoJson(msg, {
                                                                pointToLayer: function (feature, latlng) {
                                                                    marker = showmarker(feature, latlng);
                                                                    return marker;
                                                                },
                                                                onEachFeature: function (feature, layer) {
                                                                    // codice per apertura all'avvio di percorsi e aree.
                                                                    /*if((feature.properties.cordList != "") && ($('#apri_path').attr('checked')) && (feature.properties.serviceType.indexOf('Tourist_trail') == -1)){
                                                                        Estract_features(feature.properties.cordList, null ,feature.properties.serviceType);
                                                                    }*/
                                                                    var contenutoPopup = "";
                                                                    var divId = feature.id + "-" + feature.properties.tipo;
                                                                    // X TEMPI DI CARICAMENTO INFO SCHEDA ALL'APERTURA DEL POPUP LUNGHI, VISUALIZZARE NOME, LOD E TIPOLOGIA DI SERVIZIO
                                                                    /*if (feature.properties.nome != null && feature.properties.nome != "")
                                                                     contenutoPopup = "<h3>" + feature.properties.nome + "</h3>";
                                                                     else {
                                                                     if (feature.properties.identifier != null && feature.properties.identifier != "")
                                                                     contenutoPopup = "<h3>" + feature.properties.identifier + "</h3>";
                                                                     }
                                                                     contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + feature.properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                                                     contenutoPopup = contenutoPopup + "<b>Tipologia: </b>" + feature.properties.category +" - "+ feature.properties.subCategory + "<br />";*/

                                                                    contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                                                    layer.bindPopup(contenutoPopup);
                                                                    if (feature.properties.serviceType == "TransferServiceAndRenting_BusStop") {
                                                                        numeroBus++;
                                                                    }
                                                                    else {
                                                                        if (feature.properties.serviceType == "TransferServiceAndRenting_SensorSite") {
                                                                            numeroSensori++;
                                                                        }
                                                                        else {
                                                                            numeroServizi++;
                                                                        }
                                                                    }
                                                                }
                                                            })
            <%if (clusterResults > 0) {%>
                                                            if (msg.features.length >=<%=clusterResults%>) {
                                                                markers = new L.MarkerClusterGroup({maxClusterRadius: <%=clusterDistance%>, disableClusteringAtZoom: <%=noClusterAtZoom%>});
                                                                servicesLayer = markers.addLayer(servicesLayer);
                                                                //$("#cluster-msg").text("pi� di <%=clusterResults%> risultati, attivato clustering");
                                                                $("#cluster-msg").text("more than <%=clusterResults%> results, clustering enabled");
                                                                $("#cluster-msg").show();
                                                            }
                                                            else
                                                                $("#cluster-msg").hide();
            <%}%>
                                                            servicesLayer.addTo(map);
                                                            if (mode == "embed") {
                                                                for (i in servicesLayer._layers) {
                                                                    var uri = servicesLayer._layers[i].feature.properties.serviceUri;
                                                                    if (include(openPins, uri))
                                                                        servicesLayer._layers[i].openPopup();
                                                                }
                                                            }
                                                            var markerJson = JSON.stringify(msg.features);
                                                            pins = markerJson;
                                                            //numeroServizi = numeroServizi;
                                                            //numeroBus = numeroBus;

                                                            if (raggioServizi != "area") {
                                                                var confiniMappa = servicesLayer.getBounds();
                                                                map.fitBounds(confiniMappa, {padding: [50, 50]});
                                                            }
                                                            //var nResults = numeroRisultatiServizi + numeroRisultatiSensori + numeroRisultatiBus;
                                                            /*if (msg.features.length < nResults || nResults == 0) {
                                                             risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 0);
                                                             }
                                                             else {
                                                             risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 0);
                                                             }*/
                                                            if (tipo_categoria == "categorie") {
                                                                risultatiRicerca((numeroServizi + numeroBus + numeroSensori), 0, 0, 1);
                                                            } else {
                                                                //risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 2); //DA DECOMMENTARE QUANDO SISTEMATI TRANSVERSE SERVICE
                                                                risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 1);
                                                            }
                                                        }
                                                        else {
                                                            if (categorie.indexOf("PublicTransportLine") == -1) {
                                                                risultatiRicerca(0, 0, 0, 0);
                                                            }
                                                            if (raggioServizi != "area") {
                                                                map.fitBounds(clickLayer.getLayers()[1].getBounds());
                                                            }
                                                        }
                                                    }
                                                    if (categorie.indexOf("Event") != -1) {
                                                        numEventi = searchEvent("transverse", raggioServizi, centroRicerca, numeroRisultatiServizi, textFilter);
                                                        if (numEventi != 0) {
                                                            risultatiRicerca((numeroServizi + numEventi), numeroBus, numeroSensori, 1);
                                                            $("input[name=event_choice][value=day]").attr('checked', 'checked');
                                                        }
                                                    }

                                                },
                                                error: function (request, status, error) {
                                                    $('#loading').hide();
                                                    console.log(error);
                                                    risultatiRicerca(0, 0, 0, 1);
                                                }
                                            });
                                            if (categorie.indexOf("PublicTransportLine") != -1) {
                                                var i = 0;
                                                $.ajax({
                                                    url: "${pageContext.request.contextPath}/ajax/json/get-nearTPL.jsp",
                                                    type: "GET",
                                                    async: true,
                                                    dataType: 'json',
                                                    data: {
                                                        centro: centroRicerca,
                                                        raggio: raggioServizi,
                                                        numLinee: numeroRisultatiServizi
                                                    },
                                                    success: function (msg) {
                                                        if (mode == "JSON") {
                                                            $("#body").html(JSON.stringify(msg));
                                                        }
                                                        else {
                                                            $('#loading').hide();
                                                            if (msg != null && msg.PublicTransportLine.features.length > 0) {
                                                                numLineeBus = msg.PublicTransportLine.features.length;
                                                                for (i = 0; i < msg.PublicTransportLine.features.length; i++) {
                                                                    showLinea(msg.PublicTransportLine.features[i].properties.lineNumber, msg.PublicTransportLine.features[i].properties.route, msg.PublicTransportLine.features[i].properties.direction, msg.PublicTransportLine.features[i].properties.lineName, "transverse");
                                                                }
                                                                
                                                                //risultatiRicerca(msg.PublicTransportLine.features.length+numeroServizi, numeroBus, numeroSensori, 1);
                                                                $('#resultTPL').show();
                                                                var template = "{{#features}}" +
                                                                        "<div class=\"tplItem\" id=\"route_ATAF_{{properties.route}}\" style=\"margin-top:5px; border:1px solid #000; padding:6px; overflow:auto;\" onmouseover=\"selectRoute({{properties.route}})\" onmouseout=\"deselectRoute({{properties.route}})\">\n\
                                                         <div class=\"tplName\"><b style=\"color:#B500B5;\"><b>Bus Line:</b> {{properties.lineName}}</b></div>" +
                                                                        "<div class=\"tplDirection\" style=\"float:left; margin-top:7px; display:block; width:85%;\"><b>Direction:</b> {{properties.direction}}<br></div></div>" +
                                                                        "{{/features}}";
                                                                var output = Mustache.render(template, msg.PublicTransportLine);
                                                                document.getElementById('listTPL').innerHTML = output;
                                                                $(".circle.leaflet-clickable").css({stroke: "#0c0", fill: "#0c0"});
                                                                $('#numTPL').html(numLineeBus + " Bus Lines Found.");
                                                                $('#numTPL').show();
                                                                if (($('#msg').text().indexOf('not results') != -1) || ($('#msg').text().indexOf('alcun risultato') != -1) || numeroServizi == 0) {
                                                                    $('#msg').html('');
                                                                    $('#searchOutput').hide();
                                                                }
                                                                /*if(numeroServizi == 0){
                                                                    risultatiRicerca(0, 0, 0, 0);
                                                                    $(".circle.leaflet-clickable").css({stroke: "#0c0", fill: "#0c0"});
                                                                }*/
                                                            } else {
                                                                if (categorie == "PublicTransportLine" || (numeroServizi == 0)) {
                                                                    risultatiRicerca(0, 0, 0, 0);
                                                                }
                                                            }
                                                        }
                                                    }
                                                });
                                            }

                                        }
                                        else {
                                            // caso tutte le fermate oppure ricerca per comune
                                            if (pins.lenght > 0)
                                                pins = "";
                                            if (mode == "query" || mode == "embed") {
                                                var nomeComune = nomeComune;
                                                $('#loading').show();
                                            }
                                            else
                                                var nomeComune = $("#elencocomuni").val();
                                            if (selezione == "" || (selezione != null && selezione.indexOf("COMUNE di") != -1)) {
                                                var provincia = $("#elencoprovince").val();
                                                var comune = $("#elencocomuni").val();
                                                query = saveQueryMunicipality(provincia, comune, categorie, numRis, selezione);
                                                var numeroServizi = 0;
                                                var numeroBus = 0;
                                                var numeroSensori = 0;
                                                var numEventi = 0;
                                                $.ajax({
                                                    url: ctx + "/ajax/json/get-services-in-municipality.jsp",
                                                    type: "GET",
                                                    async: true,
                                                    dataType: 'json',
                                                    data: {
                                                        nomeProvincia: provincia,
                                                        nomeComune: nomeComune,
                                                        categorie: categorie,
                                                        textFilter: textFilter,
                                                        numeroRisultatiServizi: numeroRisultatiServizi,
                                                        numeroRisultatiSensori: numeroRisultatiSensori,
                                                        numeroRisultatiBus: numeroRisultatiBus,
                                                        cat_servizi: tipo_categoria
                                                    },
                                                    success: function (msg) {
                                                        //console.log(msg);
                                                        if (mode == "JSON") {
                                                            $("#body").replaceWith(JSON.stringify(msg));
                                                        }
                                                        else {
                                                            if ($("#elencocomuni").val() != 'all') {
                                                                //if (selectOption.options[selectOption.options.selectedIndex].value != 'all'){
                                                                /*
                                                                 $.ajax({
                                                                 url : "${pageContext.request.contextPath}/ajax/get-weather.jsp",
                                                                 type : "GET",
                                                                 async: true,
                                                                 //dataType: 'json',
                                                                 data : {
                                                                 nomeComune: $("#elencocomuni").val()
                                                                 },
                                                                 success : function(msg) {
                                                                 $('#info-aggiuntive .content').html(msg);
                                                                 }
                                                                 });
                                                                 */
                                                            }
                                                            var array = new Array();
                                                             var delta = new Array();
                                                            var sin = new Array();
                                                            var cos = new Array();
                                                            var sx = new Array();
                                                            var dx = new Array();
                                                            var fract = 0.523599;
                                                            var dist = 1.2;
                                                            var passo = 0.00007;
                                                        
                                                            for (var r = 0; r < 10; r++) {
                                                            array[r] = new Array();
                                                            for (var c = 0; c < 2; c++) {
                                                                array[r][c] = 0;
                                                            }
                                                                delta[r] = 0;
                                                                sin[r] = 0;
                                                                cos[r] = 0;
                                                                sx[r] = 0;
                                                                dx[r] = 0;
                                                            }

                                                            $('#loading').hide();
                                                            if (msg.features.length > 0) {
                                                                var i = 0;
                                                                var count = 0;
                                                            for (i = 0; i < msg.features.length; i++) {
                                                                if (msg.features[i].properties.serviceType == 'TourismService_Tourist_trail') {
                                                                    if (count == 0) {
                                                                        array[0][0] = msg.features[i].geometry.coordinates[0];
                                                                        array[0][1] = msg.features[i].geometry.coordinates[1];
                                                                    } else {
                                                                        for (var k = 0; k < count; k++) {
                                                                            if ((msg.features[i].geometry.coordinates[0] == array[k][0]) && (msg.features[i].geometry.coordinates[1] == array[k][1])) {
                                                                                delta[count] = (fract*count);
                                                                                sin[count] = Math.sin(delta[count]);
                                                                                cos[count] = Math.cos(delta[count]);
                                                                                sx[count] = (sin[count]*passo*dist*count);
                                                                                dx[count] = (cos[count]*passo*dist*count);;
                                                                                
                                                                                //array[count][0] = msg.features[i].geometry.coordinates[0] + (Math.random() - .4) / 1500;
                                                                                //array[count][1] = msg.features[i].geometry.coordinates[1] + (Math.random() - .4) / 1500;
                                                                                //msg.features[i].geometry.coordinates[0] = array[count][0];
                                                                                //msg.features[i].geometry.coordinates[1] = array[count][1];
                                                                                
                                                                                array[count][0] = (array[0][0])+sx[count];
                                                                                array[count][1] = (array[0][1])+dx[count];
                                                                                msg.features[i].geometry.coordinates[0] = array[count][0];
                                                                                msg.features[i].geometry.coordinates[1] = array[count][1];
                                                                            } else {
                                                                                array[count][0] = msg.features[i].geometry.coordinates[0];
                                                                                array[count][1] = msg.features[i].geometry.coordinates[1];
                                                                            }

                                                                        }

                                                                    }
                                                                    count++;
                                                                }

                                                            }
                                                                
                                                                
                                                                servicesLayer = L.geoJson(msg, {
                                                                    pointToLayer: function (feature, latlng) {
                                                                        marker = showmarker(feature, latlng);
                                                                        return marker;
                                                                    },
                                                                    onEachFeature: function (feature, layer) {
                                                                        var contenutoPopup = "";
                                                                        var divId = feature.id + "-" + feature.properties.tipo;
                                                                        // X TEMPI DI CARICAMENTO INFO SCHEDA ALL'APERTURA DEL POPUP LUNGHI, VISUALIZZARE NOME, LOD E TIPOLOGIA DI SERVIZIO
                                                                        /*if (feature.properties.nome != null && feature.properties.nome != "")
                                                                         contenutoPopup = "<h3>" + feature.properties.nome + "</h3>";
                                                                         else {
                                                                         if (feature.properties.identifier != null && feature.properties.identifier != "")
                                                                         contenutoPopup = "<h3>" + feature.properties.identifier + "</h3>";
                                                                         }
                                                                         contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + feature.properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                                                         contenutoPopup = contenutoPopup + "<b>Tipologia: </b>" + feature.properties.category +" - "+ feature.properties.subCategory + "<br />";*/
                                                                        contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                                                        layer.bindPopup(contenutoPopup);
                                                                        if (feature.properties.serviceType == "TransferServiceAndRenting_BusStop") {
                                                                            numeroBus++;
                                                                        }
                                                                        else {
                                                                            if (feature.properties.serviceType == "TransferServiceAndRenting_SensorSite") {
                                                                                numeroSensori++;
                                                                            }
                                                                            else {
                                                                                numeroServizi++;
                                                                            }
                                                                        }

                                                                    }
                                                                });
            <%if (clusterResults > 0) {%>
                                                                if (msg.features.length >=<%=clusterResults%>) {
                                                                    markers = new L.MarkerClusterGroup({maxClusterRadius: <%=clusterDistance%>, disableClusteringAtZoom: <%=noClusterAtZoom%>});
                                                                    servicesLayer = markers.addLayer(servicesLayer);
                                                                    //$("#cluster-msg").text("pi� di <%=clusterResults%> risultati, attivato clustering");
                                                                    $("#cluster-msg").text("more than <%=clusterResults%> results, clustering enabled");
                                                                    $("#cluster-msg").show();
                                                                }
                                                                else
                                                                    $("#cluster-msg").hide();
            <%}%>
                                                                servicesLayer.addTo(map);
                                                                if (mode == "embed") {
                                                                    for (i in servicesLayer._layers) {
                                                                        var uri = servicesLayer._layers[i].feature.properties.serviceUri;
                                                                        if (include(openPins, uri))
                                                                            servicesLayer._layers[i].openPopup();
                                                                    }
                                                                }
                                                                var markerJson = JSON.stringify(msg.features);
                                                                pins = markerJson;
                                                                //if (mode != "embed") {
                                                                var confiniMappa = servicesLayer.getBounds();
                                                                map.fitBounds(confiniMappa, {padding: [50, 50]});
                                                                //}
                                                                //numeroServizi = numeroServizi;
                                                                //numeroBus = numeroBus;
                                                                //numeroSensori = numeroSensori;
                                                                /*if (msg.features.length < numeroRisultati || numeroRisultati == 0) {
                                                                 risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 0);
                                                                 }
                                                                 else {
                                                                 risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 0);
                                                                 }*/
                                                                if (tipo_categoria == "categorie") {
                                                                    risultatiRicerca((numeroServizi + numeroBus + numeroSensori), 0, 0, 1);
                                                                } else {
                                                                    //risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 2); //DA DECOMMENTARE QUANDO SISTEMATI TRANSVERSE SERVICE
                                                                    risultatiRicerca(numeroServizi, numeroBus, numeroSensori, 1);
                                                                }
                                                            }
                                                            else {
                                                                risultatiRicerca(0, 0, 0, 0);
                                                            }
                                                        }
                                                        if (categorie.indexOf("Event") != -1) {
                                                            numEventi = searchEvent("transverse", null, null, numeroRisultatiServizi, textFilter);
                                                            if (numEventi != 0) {
                                                                risultatiRicerca((numeroServizi + numEventi), numeroBus, numeroSensori, 1);
                                                                $("input[name=event_choice][value=day]").attr('checked', 'checked');
                                                            }
                                                        }
                                                    },
                                                    error: function (request, status, error) {

                                                        //console.log(error);
                                                        if ($("#elencocomuni").val() != 'all') {
                                                            $.ajax({
                                                                url: "${pageContext.request.contextPath}/ajax/get-weather.jsp",
                                                                type: "GET",
                                                                async: true,
                                                                //dataType: 'json',
                                                                data: {
                                                                    nomeComune: $("#elencocomuni").val()
                                                                },
                                                                success: function (msg) {
                                                                    $('#info-aggiuntive .content').html(msg);
                                                                }
                                                            });
                                                        }
                                                        $('#loading').hide();
                                                        console.log(error);
                                                        alert('Si � verificato un errore');
                                                    }
                                                });
                                            }
                                            if (selezione != null && (selezione.indexOf("Linea Bus:") != -1) || (selezione.indexOf("Bus Line:") != -1)) {
                                                $.ajax({
                                                    url: "${pageContext.request.contextPath}/ajax/json/get-services-near-stops.jsp",
                                                    type: "GET",
                                                    async: true,
                                                    dataType: 'json',
                                                    data: {
                                                        nomeLinea: $('#elencolinee')[0].options[$('#elencolinee')[0].options.selectedIndex].value,
                                                        raggio: 100,
                                                        categorie: categorie,
                                                        numerorisultati: 100
                                                    },
                                                    success: function (msg) {
                                                        $('#loading').hide();
                                                        var i = 0;
                                                        if (msg.features.length > 0) {
                                                            servicesLayer = L.geoJson(msg, {
                                                                pointToLayer: function (feature, latlng) {
                                                                    marker = showmarker(feature, latlng);
                                                                    return marker;
                                                                },
                                                                onEachFeature: function (feature, layer) {
                                                                    var divId = feature.id + "-" + feature.properties.tipo;
                                                                    var divLinee = divId + "-linee";
                                                                    // contenutoPopup="<div id=\""+divId+"\" >";
                                                                    if (feature.properties.tipo == "fermata")
                                                                        contenutoPopup = "<h3> BUS STOP: " + feature.properties.nome + "</h3>";
                                                                    else
                                                                        contenutoPopup = "<h3>" + feature.properties.nome + "</h3>";
                                                                    contenutoPopup = contenutoPopup + "<a href='" + logEndPoint + feature.properties.serviceUri + "' title='Linked Open Graph' target='_blank'>LINKED OPEN GRAPH</a><br />";
                                                                    contenutoPopup = contenutoPopup + "Tipology: " + feature.properties.tipo + "<br />";
                                                                    if (feature.properties.email != "")
                                                                        contenutoPopup = contenutoPopup + "Email: " + feature.properties.email + "<br />";
                                                                    if (feature.properties.indirizzo != "")
                                                                        contenutoPopup = contenutoPopup + "Address: " + feature.properties.indirizzo + "<br />";
                                                                    if (feature.properties.note != "")
                                                                        contenutoPopup = contenutoPopup + "Note: " + feature.properties.note + "<br />";
                                                                    contenutoPopup += "<div id=\"" + divLinee + "\" ></div>";
                                                                    contenutoPopup = contenutoPopup + "<div id=\"" + divId + "\" ></div>";
                                                                    layer.bindPopup(contenutoPopup);
                                                                }
                                                            }).addTo(map);
                                                            var markerJson = JSON.stringify(msg.features);
                                                            pins = markerJson;
                                                            var confiniMappa = servicesLayer.getBounds();
                                                            map.fitBounds(confiniMappa, {padding: [50, 50]});
                                                            var nSer = (msg.features.length);
                                                            risultatiRicerca(msg.features.length, 0, 0, 1);
                                                        }
                                                        else {
                                                            risultatiRicerca(0, 0, 0, 0);
                                                        }
                                                    },
                                                    error: function (request, status, error) {
                                                        $('#loading').hide();
                                                        console.log(error);
                                                        alert('Si � verificato un errore');
                                                    }
                                                });
                                            }
                                        }
                                    }
                                    $('.gps-button').click(function () {
                                        if (GPSControl._isActive == true) {
                                            selezione = 'Posizione Attuale';
                                            $('#selezione').html(selezione);
                                            coordinateSelezione = "Posizione Attuale";
                                            $('#raggioricerca').prop('disabled', false);
                                            $('#raggioricerca_t').prop('disabled', false);
                                            $('#numerorisultati').prop('disabled', false);
                                            $('#PublicTransportLine').prop('disabled', false);
                                        }
                                    });
                                    $('#info img').click(function () {
                                        if ($("#info").hasClass("active") == false) {
                                            $('#info').addClass("active");
                                            selezioneAttiva = true;
                                        }
                                        else {
                                            $('#info').removeClass("active");
                                            selezioneAttiva = false;
                                        }
                                    });
                                    $('#choosePosition').click(function () {
                                        if ($("#choosePosition").hasClass("active") == false) {
                                            $('#choosePosition').addClass("active");
                                            selezioneAttiva = true;
                                        }
                                        else {
                                            $('#choosePosition').removeClass("active");
                                            selezioneAttiva = false;
                                            clickLayer.clearLayers();
                                        }
                                    });
        </script>
    </body><div id="overMap"></div>
</html>