<%@page import="java.io.IOException"%>
<%@page import="org.openrdf.model.Value"%>
<%@page import="java.util.*"%>
<%@page import="org.openrdf.repository.Repository"%>
<%@page import="org.openrdf.repository.sparql.SPARQLRepository"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.List"%>
<%@page import="org.openrdf.query.BooleanQuery"%>
<%@page import="org.openrdf.OpenRDFException"%>
<%@page import="org.openrdf.repository.RepositoryConnection"%>
<%@page import="org.openrdf.query.TupleQuery"%>
<%@page import="org.openrdf.query.TupleQueryResult"%>
<%@page import="org.openrdf.query.BindingSet"%>
<%@page import="org.openrdf.query.QueryLanguage"%>
<%@page import="java.io.File"%>
<%@page import="java.net.URL"%>
<%@page import="org.openrdf.rio.RDFFormat"%>
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

    Repository repo = new SPARQLRepository(sparqlEndpoint);
    repo.initialize();
    RepositoryConnection con = repo.getConnection();

    String nomeProvincia = request.getParameter("nomeProvincia");

    out.println("<option value=\"\"> - Seleziona un Comune - </option>");

    String filtroProvince = "";
    if (!nomeProvincia.equals("all")) {
        filtroProvince = " ?prov foaf:name \"" + nomeProvincia + "\"^^xsd:string.\n";
    }

    String queryString = "PREFIX xsd:<http://www.w3.org/2001/XMLSchema#>\n"
            + "PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"
            + "PREFIX foaf:<http://xmlns.com/foaf/0.1/>\n"
            + "PREFIX km4c:<http://www.disit.org/km4city/schema#>\n"
            + "PREFIX km4cr:<http://www.disit.org/km4city/resource#>\n"
            + "SELECT distinct ?mun ?nomeComune WHERE {\n"
            + " ?mun rdf:type km4c:Municipality.\n"
            + " ?mun km4c:isPartOfProvince ?prov.\n"
            + filtroProvince
            + "?mun foaf:name ?nomeComune.\n"
            + "}\n"
            + "ORDER BY ?nomeComune";
    //out.println(queryString);

    TupleQuery tupleQuery = con.prepareTupleQuery(QueryLanguage.SPARQL, filterQuery(queryString));
    TupleQueryResult result = tupleQuery.evaluate();
    logQuery(filterQuery(queryString),"get-municipality-list","any",nomeProvincia);
    
    try {
        while (result.hasNext()) {
            BindingSet bindingSet = result.next();
            String valueOfNomeComune = bindingSet.getValue("nomeComune").stringValue();
            out.println("<option value=\"" + valueOfNomeComune + "\">" + valueOfNomeComune + "</option>");
        }
    } catch (Exception e) {
        out.println(e.getMessage());
    }finally{con.close();}
%>