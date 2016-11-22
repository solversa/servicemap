<%@page import="org.disit.servicemap.api.ServiceMapApi"%>
<%@page import="org.disit.servicemap.api.ServiceMapApiV1"%>
<%@page  import="java.io.IOException"%>
<%@page  import="org.openrdf.model.Value"%>
<%@ page import="java.util.*"%>
<%@ page import="org.openrdf.repository.Repository"%>
<%@ page import="org.openrdf.repository.sparql.SPARQLRepository"%>
<%@ page import="java.sql.*"%>
<%@ page import="java.util.List"%>
<%@ page import="org.openrdf.query.BooleanQuery"%>
<%@ page import="org.openrdf.OpenRDFException"%>
<%@ page import="org.openrdf.repository.RepositoryConnection"%>
<%@ page import="org.openrdf.query.TupleQuery"%>
<%@ page import="java.text.ParseException"%>
<%@ page import="java.text.SimpleDateFormat"%>

<%@ page import="org.openrdf.query.TupleQueryResult"%>
<%@ page import="org.openrdf.query.BindingSet"%>
<%@ page import="org.openrdf.query.QueryLanguage"%>
<%@ page import="java.io.File"%>
<%@ page import="java.net.URL"%>
<%@ page import="org.openrdf.rio.RDFFormat"%>
<%@include file= "/include/parameters.jsp" %>
<%
/* ServiceMap.
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

    RepositoryConnection con = ServiceMap.getSparqlConnection();
    String uriFermata = request.getParameter("uriFermata");
    String divRoute = request.getParameter("divRoute");

    ServiceMapApi api= new ServiceMapApiV1();
    
    /*String queryString = " PREFIX km4c:<http://www.disit.org/km4city/schema#>\n"
              + "PREFIX km4cr:<http://www.disit.org/km4city/resource/>\n"
              + "PREFIX schema:<http://schema.org/#>\n"
              + "PREFIX xsd:<http://www.w3.org/2001/XMLSchema#>\n"
              + "PREFIX geo:<http://www.w3.org/2003/01/geo/wgs84_pos#>\n"
              + "PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"
              + "PREFIX vcard:<http://www.w3.org/2006/vcard/ns#>\n"
              + "PREFIX foaf:<http://xmlns.com/foaf/0.1/>\n"
              + "PREFIX dcterms:<http://purl.org/dc/terms/>\n"
              + "SELECT DISTINCT ?id WHERE{\n"
              + " ?tpll rdf:type km4c:PublicTransportLine.\n"
              + " ?tpll dcterms:identifier ?id.\n"
              + " ?tpll km4c:hasRoute ?route.\n"
              + " ?route km4c:hasSection ?rs.\n"
              + " ?rs km4c:endsAtStop ?bs1.\n"
              + " ?rs km4c:startsAtStop ?bs2.\n"
              + " {?bs1 foaf:name \"" + nomeFermata + "\"^^xsd:string.}\n"
              + " UNION\n"
              + " {?bs2 foaf:name \"" + nomeFermata + "\"^^xsd:string.}\n"
              + "} ORDER BY ?id ";
    
   
    TupleQuery tupleQuery = con.prepareTupleQuery(QueryLanguage.SPARQL, filterQuery(queryString));
    TupleQueryResult result = tupleQuery.evaluate();
    logQuery(filterQuery(queryString),"get-lines-of-stop","any",nomeFermata);*/

    TupleQueryResult result = api.queryBusLines(uriFermata, con);
    
        
     
    try{
        //System.out.println("testtttttttttttttttttttt-----------------");
        out.println("<div class=\"infoLinee\">");
        if(result.hasNext()){//scrivo solo per ATAF - temporaneamente
            out.println("<b>Lines:</b>");
            out.println("<table>");
            out.println("<tr>");
            while (result.hasNext()) {
                BindingSet bindingSet = result.next();
                String Line="";
                if(bindingSet.getValue("id")!=null)
                    Line = bindingSet.getValue("id").stringValue();
                else
                    Line = bindingSet.getValue("desc").stringValue();
                
                String LineUri = bindingSet.getValue("line").stringValue();
                String ag = bindingSet.getValue("ag").stringValue();
                //out.println("<td onclick='showLinea(\""+ idLine +"\")'>" + idLine + "</td>");
                out.println("<td onclick='showRoute(\""+ ag +"\",\""+ LineUri +"\",\"" + uriFermata + "\",\"" + divRoute + "\")'>" + Line + "</td>");
            }
            out.println("</tr>");
            out.println("</table>");
        }
        out.println("</div>"); 
    }catch (Exception e) {
        //MICH e.printStackTrace();
        out.println(e.getMessage());
    }finally{con.close();}
%>