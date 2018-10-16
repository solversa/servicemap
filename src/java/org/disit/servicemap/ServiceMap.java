/* ServiceMap.
   Copyright (C) 2015 DISIT Lab http://www.disit.org - University of Florence

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>. */

package org.disit.servicemap;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.io.WKTReader;
import java.io.BufferedWriter;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.sql.*;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.Scanner;
import java.util.TimeZone;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletRequest;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.openrdf.query.BindingSet;
import org.openrdf.query.QueryLanguage;
import org.openrdf.query.TupleQuery;
import org.openrdf.query.TupleQueryResult;
import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.Repository;
import org.openrdf.repository.sparql.SPARQLRepository;
import virtuoso.sesame2.driver.VirtuosoRepository;

/**
 *
 * @author bellini
 */
public class ServiceMap {
  
  static private List<String> stopWords = null;
  
  static private Map<String,String> photosAvailable = null; 
  
  static private BufferedWriter accessLog = null;
  
  static private Map<String,String> icons = null; 

  static public DateFormat dateFormatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  
  static public DateFormat dateFormatterTZ = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
  static public DateFormat dateFormatterTZ2 = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX");
  
  static public DateFormat dateFormatterGMT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ");

  static private Map<String,String> tplAgencies = null;
  
  static public ExecutorService executor = Executors.newFixedThreadPool(10);

  static public void initLogging() {
  }
  
  static public RepositoryConnection getSparqlConnection() throws Exception {
    Repository repo;
    Configuration conf = Configuration.getInstance();
    String virtuosoEndpoint = conf.get("virtuosoEndpoint", null);
    if(virtuosoEndpoint!=null && !virtuosoEndpoint.trim().isEmpty()) {
      VirtuosoRepository vrepo = new VirtuosoRepository(virtuosoEndpoint, conf.get("virtuosoUser", "dba"), conf.get("virtuosoPwd", "dba"));
      vrepo.setQueryTimeout(Integer.parseInt(conf.get("virtuosoTimeout", "600"))); //10min
      repo = vrepo;
    }
    else {
      String sparqlEndpoint = conf.get("sparqlEndpoint", null);
      repo = new SPARQLRepository(sparqlEndpoint);
    }
    repo.initialize();
    return repo.getConnection();
  }
  
  static public void logQuery(String query, String id, String type, String args, long time) {
    try {
      String queryLog = Configuration.getInstance().get("queryLogFile", "query-log.txt");
      if(!queryLog.isEmpty()) {
        File file =new File(queryLog);
        if(!file.exists()){
          file.createNewFile();
        }

        //ServiceMap.println("file: "+file.getAbsolutePath());
        //true = append file
        Date now = new Date();
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String formattedDate = formatter.format(now);
        FileWriter fileWritter = new FileWriter(file.getAbsolutePath(),true);
        BufferedWriter bufferWritter = new BufferedWriter(fileWritter);
        bufferWritter.write(("#QUERYID|"+id+"|"+type+"|"+args+"|"+(time/1000000)+"|"+formattedDate+"|"+query+"\n#####################\n").replace("\n", "\r\n"));
        bufferWritter.close();
        ServiceMap.println("#QUERYID:"+id+":"+type+":"+args+":"+(time/1000000));
        //ServiceMap.println(query);
      }
    }
    catch(Exception e) {
      ServiceMap.notifyException(e);
    }
  }
  
  static public void logAccess(HttpServletRequest request, final String email, final String sel, final String categorie, final String serviceUri, final String mode, final String numeroRisultati, final String raggio, final String queryId, final String text, final String format, final String uid, final String reqFrom) throws IOException, SQLException {
    String ip = getClientIpAddress(request);
    String ua = request.getHeader("User-Agent");
    String referer = request.getHeader("Referer");
    String site = request.getServerName();
    logAccess(ip,email,ua,sel,categorie,serviceUri,mode,numeroRisultati,raggio,queryId,text,format,uid,reqFrom,referer,site);
  }
  
  static public void logAccess(final String ip, final String email, final String UA, final String sel, final String categorie, final String serviceUri, final String mode, final String numeroRisultati, final String raggio, final String queryId, final String text, final String format, final String uid, final String reqFrom, final String referer, final String site) throws IOException, SQLException {
    final Configuration conf = Configuration.getInstance();
    File f = null;
    final Date now = new Date();
    String filePath = conf.get("accessLogFile", null);
    if (filePath != null && !filePath.trim().isEmpty()) {
      try {
        synchronized (ServiceMap.class) {
          if (accessLog == null) {
            FileWriter fstream = new FileWriter(filePath, true); //true tells to append data.
            accessLog = new BufferedWriter(fstream);
          }
        }
        accessLog.write(now + "|" + mode + "|" + ip + "|" + UA + "|" + serviceUri + "|" + email + "|" + sel + "|" + categorie + "|" + numeroRisultati + "|" + raggio + "|" + queryId + "|" + text + "|" + format + "|" + uid + "|" + reqFrom + "|" +referer+ "|" +site+"\n");
        accessLog.flush();
      } catch (Exception e) {
        ServiceMap.notifyException(e);
      }
    }

    //Class.forName("com.mysql.jdbc.Driver");
    if (conf.get("mysqlAccessLog", "true").equals("true")) {
      try {
        long tss = System.currentTimeMillis();
        Connection conMySQL = ConnectionPool.getConnection();
        if (conMySQL == null) {
          ServiceMap.println("ERROR logAccess: connection==null");
          ((ConnectionPool) ConnectionPool.getConnection()).printStatus();
          return;
        }
        // DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);;
        String query = "INSERT IGNORE INTO AccessLog(mode,ip,userAgent,serviceUri,email,selection,categories,maxResults,maxDistance,queryId,text,format,uid,reqfrom,referer,site) VALUES "
                + "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        //ServiceMap.println(query);
        PreparedStatement st = conMySQL.prepareStatement(query);
        st.setString(1, mode);
        st.setString(2, ip);
        st.setString(3, UA);
        st.setString(4, serviceUri);
        st.setString(5, email);
        st.setString(6, sel);
        st.setString(7, categorie);
        st.setString(8, numeroRisultati);
        st.setString(9, raggio);
        st.setString(10, queryId);
        st.setString(11, text);
        st.setString(12, format);
        st.setString(13, uid);
        st.setString(14, reqFrom);
        st.setString(15, referer);
        st.setString(16, site);

        st.executeUpdate();
        st.close();
        conMySQL.close();
        ServiceMap.println("mysql log time: " + (System.currentTimeMillis() - tss));
      } catch (Exception e) {
        ServiceMap.notifyException(e);
      }
    }
    if (conf.get("phoenixAccessLog", "true").equals("true")) {
      executor.submit(new Runnable() {
        @Override
        public void run() {
          try {
            long ts = System.currentTimeMillis();
            Class.forName("org.apache.phoenix.jdbc.PhoenixDriver");
            Connection con = DriverManager.getConnection(conf.get("phoenixJDBC", "jdbc:phoenix:192.168.0.118"));
            String query2 = "UPSERT INTO AccessLog(id,timestamp,mode,ip,userAgent,serviceUri,email,selection,categories,maxResults,maxDistance,queryId,text,format,uid,reqfrom,referer,site) VALUES "
                    + "( NEXT VALUE FOR accesslog_sequence,NOW(),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
            PreparedStatement stmt = con.prepareStatement(query2);
            stmt.setString(1, mode);
            stmt.setString(2, ip);
            stmt.setString(3, UA);
            stmt.setString(4, serviceUri);
            stmt.setString(5, email);
            stmt.setString(6, sel);
            stmt.setString(7, categorie);
            stmt.setString(8, numeroRisultati);
            stmt.setString(9, raggio);
            stmt.setString(10, queryId);
            stmt.setString(11, text);
            stmt.setString(12, format);
            stmt.setString(13, uid);
            stmt.setString(14, reqFrom);
            stmt.setString(15, referer);
            stmt.setString(16, site);

            stmt.setQueryTimeout(Integer.parseInt(conf.get("phoenixQueryTimeoutSeconds", "10")));

            stmt.executeUpdate();
            stmt.close();
            con.commit();
            con.close();
            ServiceMap.println("phoenix log time: " + (System.currentTimeMillis() - ts));
          } catch (Exception e) {
            ServiceMap.notifyException(e);
          }
        }
      });
    }
  }
  
  static public void logNoRoute(Object r) {
    try {
      String norouteLog = Configuration.getInstance().get("noRouteLogFile", "noroute.log");
      File file =new File(norouteLog);
      if(!file.exists()){
        file.createNewFile();
      }

      Date now = new Date();
      SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
      String formattedDate = formatter.format(now);
      FileWriter fileWriter = new FileWriter(file.getAbsolutePath(),true);
      BufferedWriter noRouteLog = new BufferedWriter(fileWriter);
      noRouteLog.write( formattedDate + "|" + r.toString() + "\n");
      noRouteLog.close();
    }
    catch(Exception e) {
      ServiceMap.notifyException(e);
    }
  }

  static public String escapeJSON(String s) {
    if(s==null)
      return null;
    return JSONObject.escape(s); //)s.replace("\"", "\\\"").replace("\t", "\\t").replace("\n", "\\n");
  }

  static final public String prefixes =
              "PREFIX km4c:<http://www.disit.org/km4city/schema#>\n"
            + "PREFIX km4cr:<http://www.disit.org/km4city/resource/>\n"
            + "PREFIX schema:<http://schema.org/>\n"
            + "PREFIX xsd:<http://www.w3.org/2001/XMLSchema#>\n"
            + "PREFIX geo:<http://www.w3.org/2003/01/geo/wgs84_pos#>\n"
            + "PREFIX omgeo:<http://www.ontotext.com/owlim/geo#>\n"
            + "PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"
            + "PREFIX vcard:<http://www.w3.org/2006/vcard/ns#>\n"
            + "PREFIX foaf:<http://xmlns.com/foaf/0.1/>\n"
            + "PREFIX dcterms:<http://purl.org/dc/terms/>\n"
            + "PREFIX opengis:<http://www.opengis.net/ont/geosparql#>\n";
  
  
   static public String routeLineQuery(String line) {
    String filtroLinee = "";
    if (!line.equals("all")) {
      filtroLinee = " ?tpll dcterms:identifier \"" + line + "\"^^xsd:string.\n";
    }
    return  prefixes 
   
            + "SELECT DISTINCT ?dir ?line ?rName ?code ?bsFirst ?bsLast ?x WHERE{\n"
              + " ?tpll rdf:type km4c:PublicTransportLine.\n"
              + " ?tpll dcterms:identifier ?line.\n"
              + filtroLinee      
              + " ?tpll km4c:hasRoute ?route.\n"
              + " ?route km4c:hasFirstStop ?bss.\n"
              + " ?route km4c:hasLastStop ?bse.\n"
              + " ?route km4c:direction ?dir.\n"
              + " ?route dcterms:identifier ?code.\n"
              + " ?bss foaf:name ?bsFirst.\n"
              + " ?bse foaf:name ?bsLast.\n"
              + " ?route foaf:name ?rName.\n"
              + " ?route opengis:hasGeometry ?geometry .\n"
              + " ?geometry opengis:asWKT ?polyline .\n"
              + "} ORDER BY ?line ?dir ";
  }
  
  static public String busLineQuery(String route) {
    /*String filtroLinee = "";
    if (!line.equals("all")) {
      filtroLinee = " ?tpll dcterms:identifier \"" + line + "\"^^xsd:string.\n";
    }*/
    return  prefixes 
            + "SELECT DISTINCT ?nomeFermata ?x WHERE {\n"
            + " ?tpll rdf:type km4c:PublicTransportLine.\n"
            //+ filtroLinee
            + " ?tpll km4c:hasRoute ?route.\n"
            + " ?route dcterms:identifier \"" + route + "\".\n"
            + "?route km4c:hasSection ?rs.\n"
            + " ?rs km4c:endsAtStop ?bs1.\n"
            + " ?rs km4c:startsAtStop ?bs2.\n"
            + " { ?bs1 foaf:name ?nomeFermata. }\n"
            + " UNION\n"
            + " { ?bs2 foaf:name ?nomeFermata. }\n"
            + "} ORDER BY ?nomeFermata";  
  }
  
  static public String latLngToAddressQuery(String lat, String lng, String sparqlType) {
    return prefixes
            + "SELECT DISTINCT ?via ?numero ?comune	(?nc as ?uriCivico) ?uriComune ?provincia ?uriProvincia WHERE {\n"
            + " ?entry rdf:type km4c:Entry.\n"
            + " ?nc km4c:hasExternalAccess ?entry.\n"
            + " ?nc km4c:extendNumber ?numero.\n"
            + " ?nc km4c:belongToRoad ?road.\n"
            + " ?road km4c:extendName ?via.\n"
            + " ?entry geo:lat ?elat.\n"
            + " ?entry geo:long ?elong.\n"
            + " ?road km4c:inMunicipalityOf ?uriComune.\n"
            + " ?uriComune foaf:name ?comune.\n"
            + " ?uriComune km4c:isPartOfProvince ?uriProvincia.\n"
            + " ?uriProvincia foaf:name ?provincia.\n"
            + (sparqlType.equals("virtuoso") ? 
               //" ?ser geo:geometry ?geo.  filter(bif:st_distance(?geo, bif:st_point ("+longitudine+","+latitudine+"))<= "+raggioBus+")" :
                 " ?entry geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), 0.3))\n" 
               + " BIND( bif:st_distance(?geo, bif:st_point(" + lng + ", " + lat + ")) AS ?dist)\n":
                 " ?entry omgeo:nearby(" + lat + " " + lng + " \"0.3km\").\n"
               + " BIND( omgeo:distance(?elat, ?elong, " + lat + ", " + lng + ") AS ?dist)\n")
            + "} ORDER BY ?dist "
            + "LIMIT 1";
  }
  
  static public String latLngToMunicipalityQuery(String lat, String lng, String sparqlType) {
    return prefixes
            + "SELECT DISTINCT ?comune ?uriComune ?provincia ?uriProvincia ?dist WHERE {\n"
            + " ?entry rdf:type km4c:Entry.\n"
            + " ?nc km4c:hasExternalAccess ?entry.\n"
            + " ?nc km4c:belongToRoad ?road.\n"
            + " ?entry geo:lat ?elat.\n"
            + " ?entry geo:long ?elong.\n"
            + " ?road km4c:inMunicipalityOf ?uriComune.\n"
            + " ?uriComune foaf:name ?comune.\n"
            + " ?uriComune km4c:isPartOfProvince ?uriProvincia.\n"
            + " ?uriProvincia foaf:name ?provincia.\n"
            + (sparqlType.equals("virtuoso") ? 
               //" ?ser geo:geometry ?geo.  filter(bif:st_distance(?geo, bif:st_point ("+longitudine+","+latitudine+"))<= "+raggioBus+")" :
                 " ?entry geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), 5))\n" 
               + " BIND( bif:st_distance(?geo, bif:st_point(" + lng + ", " + lat + ")) AS ?dist)\n":
                 " ?entry omgeo:nearby(" + lat + " " + lng + " \"5km\").\n"
               + " BIND( omgeo:distance(?elat, ?elong, " + lat + ", " + lng + ") AS ?dist)\n")
            + "} ORDER BY ?dist "
            + "LIMIT 1";
  }
  
  static public String servicesNearLatLongQuery(String lat, String lng) {
    return "";
  }
  
  static public ArrayList<String> getTypes(RepositoryConnection con, String uri) {
    return ServiceMap.getTypes(con, uri, true);
  }
  
  static public ArrayList<String> getTypes(RepositoryConnection con, String uri, boolean inference) {
    Configuration conf = Configuration.getInstance();
    String sparqlType = conf.get("sparqlType", "");
    
    String queryString
            = "PREFIX km4c:<http://www.disit.org/km4city/schema#>"
            + "PREFIX km4cr:<http://www.disit.org/km4city/resource#>"
            + "PREFIX xsd:<http://www.w3.org/2001/XMLSchema#>"
            + "PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>"
            + "SELECT DISTINCT ?type WHERE{"
            + " <" + uri + "> rdf:type ?type"+(sparqlType.equals("virtuoso") && inference ? " OPTION (inference \"urn:ontology\")":"")+".\n"
            + "}";

    ArrayList<String> types=new ArrayList<String>();
    try {
      TupleQuery tupleQuery = con.prepareTupleQuery(QueryLanguage.SPARQL, queryString);
      long ts = System.nanoTime();
      TupleQueryResult result = tupleQuery.evaluate();
      logQuery(queryString, "get-types", sparqlType, uri+";"+inference,System.nanoTime()-ts);
      while (result.hasNext()) {
        BindingSet bindingSet = result.next();
        String type = bindingSet.getValue("type").stringValue();
        type = type.replace("http://www.disit.org/km4city/schema#", "");
        types.add(type);
      }
    } catch (Exception e) {
      ServiceMap.notifyException(e);
    }
    return types;
  }

  static public String filterServices(List<String> listaCategorie) throws Exception {      
    String filtroQuery = "";
    Configuration conf = Configuration.getInstance();
    String sparqlType = conf.get("sparqlType", "");
    String km4cVersion = conf.get("km4cVersion", "");
    String urlMySqlDB = conf.get("urlMySqlDB", "");
    String dbMySql = conf.get("dbMySql", "");
    String userMySql = conf.get("userMySql", "");
    String passMySql = conf.get("passMySql", "");

    if(!km4cVersion.equals("old")) {
      /*int n=0;
      for(String c:listaCategorie) {
        if(!c.equals("Service") && !c.equals("NearBusStops") && !c.equals("RoadSensor")) {
          if(n>0)
            filtroQuery += "UNION";
          filtroQuery += " { ?ser a km4c:"+(c.substring(0, 1).toUpperCase()+c.substring(1))+(sparqlType.equals("virtuoso")? " OPTION (inference \"urn:ontology\")":"")+".}\n";
          n++;
        }
      }*/
      //if(listaCategorie.contains("theatre"))
      //  listaCategorie.add("teathre"); //FIX DA RIMUOVERE
      String microCat="";
      String mCats[] = {"Accommodation", "Advertising", "AgricultureAndLivestock", "CivilAndEdilEngineering", "CulturalActivity", "EducationAndResearch", "Emergency", "Environment", "Entertainment", "FinancialService",
        "GovernmentOffice", "HealthCare", "IndustryAndManufacturing", "MiningAndQuarrying", "ShoppingAndService", "TourismService", "TransferServiceAndRenting", "UtilitiesAndSupply", "Wholesale", "WineAndFood","IoTDevice"};
      List<String> macroCats=Arrays.asList(mCats); //TODO prendere da query e fare caching
      int n=0;
      for(String c:listaCategorie) {
        //FIX temporaneo
        c = c.trim().replace(" ", "_");
        c = c.substring(0, 1).toUpperCase()+c.substring(1);
        if(macroCats.contains(c)) {
          if(n>0)
            filtroQuery += "UNION";
          filtroQuery += " { ?ser a km4c:"+c+(sparqlType.equals("virtuoso")? " OPTION (inference \"urn:ontology\")":"")+".}\n";
          n++;
        }
        else if(!c.equals("Service") && !c.equals("BusStop") && !c.equals("SensorSite") && !c.equals("Event") && !c.equals("PublicTransportLine")) {
          if(microCat.length()>0)
            microCat+=",";
          microCat+="km4c:"+c+"\n";
        }
      }
      if(microCat.length()>0) {
        if(filtroQuery.length()>0) {
          filtroQuery += "UNION ";
        }
        filtroQuery += "{ ?ser a ?t. FILTER(?t IN ("+microCat+"))}\n";
      }
      return filtroQuery;          
    }

    Connection conMySQL = null;
    Statement st = null;
    ResultSet rs = null;

    //Class.forName("com.mysql.jdbc.Driver");
    conMySQL = ConnectionPool.getConnection(); //DriverManager.getConnection(urlMySqlDB + dbMySql, userMySql, passMySql);;

    String query = "SELECT distinct Ita, Eng FROM SiiMobility.ServiceCategory ORDER BY SubClasse";

    // create the java statement
    st = conMySQL.createStatement();

    // execute the query, and get a java resultset
    rs = st.executeQuery(query);
    int categorieInserite = 0;
    while (rs.next()) {
        //String id = rs.getString("ID");
        String nomeEng = rs.getString("Eng");
        String nomeIta = rs.getString("Ita");
        String NomeIta = Character.toUpperCase(nomeIta.charAt(0)) + nomeIta.substring(1);
        NomeIta = NomeIta.replace("_", " ");

        if (listaCategorie.contains(nomeEng) || listaCategorie.contains(nomeIta)) {
            if (categorieInserite == 0) {
                filtroQuery += " { ?ser km4c:hasServiceCategory <http://www.disit.org/km4city/resource/" + nomeEng + ">.\n";
                filtroQuery += " BIND (\"" + nomeEng + "\"^^xsd:string AS ?sType).\n";
                filtroQuery += " BIND (\"" + NomeIta + "\"^^xsd:string AS ?sTypeIta) }\n";
            } else {
                filtroQuery += " UNION {?ser km4c:hasServiceCategory <http://www.disit.org/km4city/resource/" + nomeEng + ">.\n";
                filtroQuery += " BIND (\"" + nomeEng + "\"^^xsd:string AS ?sType).\n";
                filtroQuery += " BIND (\"" + NomeIta + "\"^^xsd:string AS ?sTypeIta)}\n";
            }
            categorieInserite++;
        }
    }
    st.close();
    conMySQL.close();
    return filtroQuery;
  }
  
  static public String textSearchQueryFragment(String subj, String pred, String textToSearch) throws Exception {
    if(textToSearch==null || textToSearch.equals(""))
      return "";
    Configuration conf = Configuration.getInstance();
    String sparqlType = conf.get("sparqlType", "virtuoso");
    boolean removeStopWords = conf.get("removeStopWords", "true").equals("true");

    loadStopWords();

    int n = 0;
    if (sparqlType.equals("virtuoso")) {
        String[] s = textToSearch.split(" +");
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length; i++) {
          String word = s[i].trim().replaceAll("[^a-zA-Z0-9]", "");
          if(!removeStopWords || !stopWords.contains(word)) {
            if(n>0)
              sb.append(" and ");
            sb.append("'"+word+"'");
            n++;
          }
        }
        textToSearch = sb.toString();
        if("".equals(textToSearch))
          return "";
    }
    ServiceMap.println("search "+textToSearch);
    return " "+subj+" "+pred+" ?txt.\n"
       + (sparqlType.equals("owlim")
          ? " ?txt luc:myIndex \"" + textToSearch + "\".\n"
          + " ?txt luc:score ?sc.\n"
          : " ?txt bif:contains \"" + textToSearch + "\" OPTION (score ?sc).\n");
  }
  
  static private void loadStopWords() {
    if(stopWords != null)
      return; //already loaded;

    stopWords = new ArrayList<String>();
    String token1 = "";
    try {
      // create Scanner
      Scanner scanner = new Scanner(new File(System.getProperty("user.home")+"/servicemap/stop_words.txt"));
      while (scanner.hasNext()) {
        // find next line
        token1 = scanner.next();
        //ServiceMap.println("-"+token1+"-");
        stopWords.add(token1);
      }
      scanner.close();    
    } catch (FileNotFoundException ex) {
      ServiceMap.notifyException(ex);
    }
  }
  
  static public String geoSearchQueryFragment(String subj, String lat, String lng, String dist) {
    if (lat == null || lng == null || dist == null) {
      return "";
    }

    Configuration conf = Configuration.getInstance();
    String sparqlType = conf.get("sparqlType", "virtuoso");

    return (sparqlType.equals("virtuoso")
            ? " " + subj + " geo:geometry ?geo.  filter(IF(bif:GeometryType(?geo)=\"POINT\",bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + ")),100)<= " + dist + ")\n"
            + " BIND(IF(bif:GeometryType(?geo)=\"POINT\",bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + ")),100) AS ?dist)\n"
            //"  ?entry geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), "+dist+"))\n" :
            : " " + subj + " omgeo:nearby(" + lat + " " + lng + " \"" + dist + "km\") .\n"); //ATTENZIONE per OWLIM non viene aggiunto il BIND
  }
  
  static public String geoSearchQueryFragment(String subj, String[] coords, String dist) throws IOException, SQLException {
    if (coords==null || (!coords[0].startsWith("wkt:") && !coords[0].startsWith("geo:") && coords.length!=2 && coords.length!=4) || dist == null ) {
      return "";
    }

    Configuration conf = Configuration.getInstance();
    String sparqlType = conf.get("sparqlType", "virtuoso");

    if(coords.length==1 && (coords[0].startsWith("wkt:") || coords[0].startsWith("geo:"))) {
      String geom = coords[0].substring(4);
      if(coords[0].startsWith("geo:")) {
        //cerca su tabella la geometria dove fare ricerca
        Connection conMySQL = ConnectionPool.getConnection();
        Statement st = conMySQL.createStatement();
        ResultSet rs = st.executeQuery("SELECT wkt FROM Geometry WHERE label='"+geom+"'");
        if (rs.next()) {
          geom = rs.getString("wkt");
        }
        else 
          throw new IOException("geometry "+geom+" not found");
        st.close();
        conMySQL.close();
      }
      return  " " + subj + " geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_geomfromtext(\""+geom+"\"), 0.0005))\n"
              + " BIND( 1.0 AS ?dist)\n";
    }

    for(int i=0;i<coords.length; i++)
      Double.parseDouble(coords[i]);
    
    String lat = coords[0];
    String lng = coords[1];
    
    if(coords.length==2) {
      if(sparqlType.equals("virtuoso")) {
        if(conf.get("geometrySearchType", "distance").equalsIgnoreCase("distance")) {
          if(conf.get("forcePointCheck","false").equals("true")) //in alcuni casi fallisce st_distance
          return //IF(bif:GeometryType(?geo)=\"POINT\",...,100)
               " " + subj + " geo:geometry ?geo.  filter(IF(bif:GeometryType(?geo)=\"POINT\",bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + ")),100)<= " + dist + ")\n"
              //"  " + subj + " geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), "+dist+"))\n"
              + " BIND(IF(bif:GeometryType(?geo)=\"POINT\",bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + ")),100) AS ?dist)\n";
        else
          return " " + subj + " geo:geometry ?geo.  filter(bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + "))<= " + dist + ")\n"
              //"  " + subj + " geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), "+dist+"))\n"
              + " BIND(bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + ")) AS ?dist)\n";
        } else {          
          return "  " + subj + " geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), "+dist+"))\n"
              + " BIND(bif:st_distance(?geo, bif:st_point (" + lng + "," + lat + ")) AS ?dist)\n";
        }
      }
      else
        return " " + subj + " omgeo:nearby(" + lat + " " + lng + " \"" + dist + "km\") .\n"; //ATTENZIONE per OWLIM non viene aggiunto il BIND
    }
    String lat2 = coords[2];
    String lng2 = coords[3];
    if(sparqlType.equals("virtuoso")) {
      if(conf.get("geometrySearchType", "distance").equalsIgnoreCase("distance")) {
        return " " + subj + " geo:geometry ?geo.  filter(bif:st_x(?geo)>=" + lng + " && bif:st_x(?geo)<=" + lng2 + " && bif:st_y(?geo)>=" + lat + " && bif:st_y(?geo)<=" + lat2 + ")\n"
            + " BIND(bif:st_distance(?geo, bif:st_point (" + (Float.parseFloat(lng)+Float.parseFloat(lng2))/2. + "," + (Float.parseFloat(lat)+Float.parseFloat(lat2))/2. + ")) AS ?dist)\n";
            //"  ?entry geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_point ("+lng+","+lat+"), "+dist+"))\n" :
      }
      else //use intersects
        return " " + subj + " geo:geometry ?geo.  filter(bif:st_intersects (?geo, bif:st_geomfromtext(\"POLYGON(("+lng+" "+lat+","+lng+" "+lat2+","+lng2+" "+lat2+","+lng2+" "+lat+","+lng+" "+lat+"))\"), 0))\n"
            + " BIND(bif:st_distance(?geo, bif:st_point (" + (Float.parseFloat(lng)+Float.parseFloat(lng2))/2. + "," + (Float.parseFloat(lat)+Float.parseFloat(lat2))/2. + ")) AS ?dist)\n";
    }
    else {
      return " " + subj + " omgeo:nearby(" + lat + " " + lng + " \"" + dist + "km\") .\n"; 
      //ATTENZIONE per OWLIM non viene aggiunto il BIND    
    }
  }
  
  static public String valueTypeSearchQueryFragment(String subj, String value_type) {
    if(value_type==null || value_type.trim().isEmpty())
      return "";
    value_type = value_type.trim();
    if(!value_type.startsWith("http:"))
      value_type = "http://www.disit.org/km4city/resource/value_type/"+value_type;
    return subj+" sosa:observes <"+value_type+">.\n";
  }

  static public String graphSearchQueryFragment(String subj, String graphUri) {
    if (graphUri==null) {
      return "";
    }

    Configuration conf = Configuration.getInstance();
    String sparqlType = conf.get("sparqlType", "virtuoso");

    return "FILTER EXISTS {GRAPH <"+graphUri+"> { "+subj+" a ?anyclass }}\n";
  }
  
  static public JsonObject computeHealthiness(JsonArray rtData, JsonObject rtAttrs) throws Exception {
    Configuration conf=Configuration.getInstance();
    JsonObject health = new JsonObject();
    if(rtData==null || rtAttrs==null)
      return health;
    
    boolean healthy = false;
    Date now = new Date();
    Date lastDate = null;
    String reason = null;
    JsonObject last = null;
    if(rtData.size()>0) {
      last = rtData.get(0).getAsJsonObject();
      String lastTime = last.get("measuredTime").getAsString();
      try {
        lastDate = ServiceMap.dateFormatterTZ.parse(lastTime);
      } catch(ParseException e) {
        lastDate = ServiceMap.dateFormatterTZ2.parse(lastTime);
      }
      ServiceMap.println("health: "+lastDate+" now: "+now+" diff:"+(lastDate!=null ? (now.getTime()-lastDate.getTime())/1000 : -1)+"s");
    } else {
      ServiceMap.println("health: no rt data");
      reason = "no RT data";
    }
    for(Entry<String,JsonElement> e : rtAttrs.entrySet()) {
      String name=e.getKey();
      healthy = false;
      reason = null;
      int refreshRate = Integer.parseInt(e.getValue().getAsJsonObject().get("value_refresh_rate").getAsString());
      JsonObject h = new JsonObject();
      if(lastDate!=null) {
        long delay = (now.getTime()-lastDate.getTime())/1000;
        long defaultRefreshRate = Integer.parseInt(conf.get("defaultRefreshRate","-1"));
        h.addProperty("delay", delay);
        if(delay<refreshRate || delay<defaultRefreshRate) {
          if(last.get(name)!=null && !last.get(name).getAsString().isEmpty())
            healthy=true;
          else
            reason = "missing value";
        }
        else {
          reason = "too old data "+delay+">="+refreshRate+" && delay>="+defaultRefreshRate;
        }
      }
      if (reason!=null)
        h.addProperty("reason",reason);
      h.addProperty("healthy", healthy);
      health.add(name, h);
    }
    return health;
  }
  
  static public String toFloat(String a, String b) {
    //return " (bif:sprintf(\"%.10f\","+a+") AS "+b+")";
    return " ("+a+" AS "+b+")";
  }
  
  static public int countQuery(RepositoryConnection con, String query) throws Exception {
    //return -1;
    TupleQuery tupleQuery = con.prepareTupleQuery(QueryLanguage.SPARQL, query);
    long ts = System.currentTimeMillis();
    TupleQueryResult result = tupleQuery.evaluate();
    ServiceMap.println("SPARQL count time:"+(System.currentTimeMillis()-ts));
    if(result.hasNext()) {
      BindingSet binding = result.next();
      String count = binding.getValue("count").stringValue();
      return Integer.parseInt(count);
    }
    return 0;
  }
  
  static public boolean sendEmail(String dest, String subject, String msg, String mimeType) {
    boolean emailSent;
    String to[] = dest.split(";");
    Properties properties = System.getProperties();
    Configuration conf=Configuration.getInstance();
    properties.put("mail.smtp.host", conf.get("smtp", "musicnetwork.dsi.unifi.it"));
    properties.put("mail.smtp.port", conf.get("portSmtp","25"));
    String auth = conf.get("authSmtp","false");
    if(auth.equals("true")) {
      properties.put("mail.smtp.auth", auth);
      String authType = conf.get("authTypeSmtp","TLS");
      if(authType.equals("TLS"))
        properties.put("mail.smtp.starttls.enable", "true");
      else if(authType.equals("SSL")) {
        properties.put("mail.smtp.socketFactory.port", conf.get("portSmtp","465"));
        properties.put("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
      }
    }
    final String user = conf.get("userSmtp", null);
    final String passwd = conf.get("passwdSmtp", "");
    Session mailSession = Session.getDefaultInstance(properties);
    if(user!=null && !user.trim().isEmpty()) {
      properties.setProperty("mail.user", user);
      properties.setProperty("mail.password", passwd);
      mailSession = Session.getInstance(properties,
        new javax.mail.Authenticator() {
        protected PasswordAuthentication getPasswordAuthentication() {
          return new PasswordAuthentication(user, passwd);
        }
        });
    }
    try {
      MimeMessage message = new MimeMessage(mailSession);
      message.setFrom(new InternetAddress(conf.get("mailFrom","info@disit.org")));
      for(String t: to)
        message.addRecipient(Message.RecipientType.TO,
              new InternetAddress(t));
      message.setSubject(subject);
      message.setContent(msg, mimeType==null ? "text/plain; charset=utf-8" : mimeType);
      Transport.send(message);
      emailSent = true;
    } catch (MessagingException mex) {
      ServiceMap.notifyException(mex);
      emailSent = false;
    }        
    return emailSent;
  }
  
  static public String getServiceName(String serviceUri) throws Exception {
    RepositoryConnection con = ServiceMap.getSparqlConnection();
    String serviceName = getServiceName(con, serviceUri);
    con.close();
    return serviceName;
  }
  
  static public String getServiceName(RepositoryConnection con, String serviceUri) throws Exception {
    String serviceName = null;
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, "SELECT * WHERE {{<"+serviceUri+"> <http://schema.org/name> ?name}UNION{<"+serviceUri+"> <http://xmlns.com/foaf/0.1/name> ?name}} LIMIT 1");
    TupleQueryResult result = tq.evaluate();
    if(result.hasNext()) {
      BindingSet binding = result.next();
      serviceName = binding.getValue("name").stringValue();
    }
    return serviceName;
  }
  
  static public String getServiceIdentifier(RepositoryConnection con, String serviceUri) throws Exception {
    String serviceId = null;
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, "SELECT * WHERE {<"+serviceUri+"> <http://purl.org/dc/terms/identifier> ?id} LIMIT 1");
    TupleQueryResult result = tq.evaluate();
    if(result.hasNext()) {
      BindingSet binding = result.next();
      serviceId = binding.getValue("id").stringValue();
    }
    return serviceId;
  }
  
  static public Map<String,String> getServiceInfo(String idService, String lang) throws Exception {
    Map<String,String> info = new HashMap<>();
    RepositoryConnection con = ServiceMap.getSparqlConnection();
    String queryService = "PREFIX km4c:<http://www.disit.org/km4city/schema#>\n"
            + "PREFIX geo:<http://www.w3.org/2003/01/geo/wgs84_pos#>\n"
            + "PREFIX xsd:<http://www.w3.org/2001/XMLSchema#>\n"
            + "PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"
            + "PREFIX schema:<http://schema.org/>\n"
            + "PREFIX skos:<http://www.w3.org/2004/02/skos/core#>\n"
            + "PREFIX dcterms:<http://purl.org/dc/terms/>\n"
            + "PREFIX opengis:<http://www.opengis.net/ont/geosparql#>\n"
            + "PREFIX gtfs:<http://vocab.gtfs.org/terms#>\n"
            + "SELECT ?name ?lat ?long ?type ?category ?typeLabel ?ag ?agname WHERE{\n"
            + " {\n"
            + "  <" + idService + "> km4c:hasAccess ?entry.\n"
            + "  ?entry geo:lat ?lat.\n"
            + "  ?entry geo:long ?long.\n"
            + " }UNION{\n"
            + "  <" + idService + "> km4c:isInRoad ?road.\n"
            + "  <" + idService + "> geo:lat ?lat.\n"
            + "  <" + idService + "> geo:long ?long.\n"
            + " }UNION{\n"
            + "  <" + idService + "> geo:lat ?lat.\n"
            + "  <" + idService + "> geo:long ?long.\n"
            + " }\n"
            + " {<" + idService + "> schema:name ?name.}UNION{<" + idService + "> foaf:name ?name.}UNION{<" + idService + "> dcterms:identifier ?name.}\n"
            + " <" + idService + "> a ?type . FILTER(?type!=km4c:RegularService && ?type!=km4c:Service && ?type!=km4c:DigitalLocation)\n"
            + " ?type rdfs:label ?typeLabel. FILTER(LANG(?typeLabel) = \""+lang+"\")\n"
            + " OPTIONAL{?type rdfs:subClassOf ?category FILTER(STRSTARTS(STR(?category),\"http://www.disit.org/km4city/schema#\"))}.\n"
            + " OPTIONAL {\n"
            + "  {?st gtfs:stop <"+idService+">.}UNION{?st gtfs:stop [owl:sameAs <"+idService+">]}\n" 
            + "  ?st gtfs:trip ?t.\n"
            +"   ?t gtfs:route/gtfs:agency ?ag.\n"
            +"   ?ag foaf:name ?agname.\n"
            + " }\n"
            + "} LIMIT 1";
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, queryService);
    TupleQueryResult result = tq.evaluate();
    if(result.hasNext()) {
      BindingSet binding = result.next();
      info.put("serviceName", binding.getValue("name").stringValue());
      info.put("lat", binding.getValue("lat").stringValue());
      info.put("long", binding.getValue("long").stringValue());
      info.put("typeLabel", binding.getValue("typeLabel").stringValue());
      if(binding.getValue("category")!=null)
        info.put("serviceType", makeServiceType(binding.getValue("category").stringValue(), binding.getValue("type").stringValue()));
      else
        info.put("serviceType", binding.getValue("type").stringValue().replace("http://www.disit.org/km4city/schema#", ""));
      if(binding.getValue("ag")!=null) {
        info.put("agencyUri", binding.getValue("ag").stringValue());
        info.put("agency", binding.getValue("agname").stringValue());
      }
    }
    con.close();
    
    return info;
  }
  
  static public String map2Json(Map<String,String> info) throws Exception {
    String json  = "";
    for(String k:info.keySet()) {
      json += "\""+k+"\":\""+escapeJSON(info.get(k))+"\", ";
    }
    return json;
  }
  
  static public Map<String,String> getUriInfo(String uri) throws Exception {
    Map<String,String> info = new HashMap<>();
    RepositoryConnection con = ServiceMap.getSparqlConnection();
    String query="SELECT * WHERE { <"+uri+"> ?p ?o }";
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, query);
    TupleQueryResult result = tq.evaluate();
    while(result.hasNext()) {
      BindingSet binding = result.next();
      String p = binding.getValue("p").stringValue();
      String o = binding.getValue("o").stringValue();
      info.put(p,o);
    }
    con.close();
    return info;
  }
  
  static public JSONObject getStopFromOsmNodeId(RepositoryConnection con, String node_id, String agency_id) throws Exception {
    String stopUri = "";
    String stopName = "";
    String agencyUri = "";
    String agencyName = "";
    String serviceType = "";
    String query="SELECT DISTINCT ?stop ?name ?class ?mclass ?agency ?agencyName WHERE {"
            + " ?stop foaf:based_near <http://www.disit.org/km4city/resource/OS"+
            String.format("%11s", node_id).replace(' ', '0')+"NO>. "
            + " ?stop gtfs:agency ?agency."
            + " ?agency foaf:name ?agencyName."
            + " ?stop foaf:name ?name. "
            + " ?stop a ?class."
            + " ?class rdfs:subClassOf ?mclass."
            + " ?mclass rdfs:subClassOf km4c:Service. }";
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, query);
    TupleQueryResult result = tq.evaluate();
    while(result.hasNext()) {
      BindingSet binding = result.next();
      agencyUri = binding.getValue("agency").stringValue();
      if(agencyUri.endsWith("_"+agency_id)) {
        stopUri = binding.getValue("stop").stringValue();
        stopName = binding.getValue("name").stringValue();
        agencyName = binding.getValue("agencyName").stringValue();
        String _class = binding.getValue("class").stringValue().replace("http://www.disit.org/km4city/schema#", "");
        String macroClass = binding.getValue("mclass").stringValue().replace("http://www.disit.org/km4city/schema#", "");
        serviceType = macroClass+"_"+_class;
        break;
      }
    }
    JSONObject stop = new JSONObject();
    stop.put("uri", stopUri);
    stop.put("name", stopName);
    stop.put("agencyName", agencyName);
    stop.put("agencyUri", agencyUri);
    stop.put("serviceType", serviceType);
    return stop;
  }

  static public JSONObject getStopFromId(RepositoryConnection con, String stop_id, String agency_id) throws Exception {
    String stopUri = "";
    String stopName = "";
    String agencyUri = "";
    String agencyName = "";
    String serviceType = "";
    
    String prefix = getTplAgencyPrefix(con, agency_id);
    
    String query="SELECT DISTINCT ?stop ?name ?class ?mclass ?agency ?agencyName WHERE {\n" +
      " BIND(<"+prefix+"_Stop_"+stop_id+"> as ?stop)\n" +
      " BIND(<"+prefix+"_Agency_"+agency_id+"> as ?agency)\n" +
      //" ?stop a gtfs:Stop.\n" +
      //" filter(strends(str(?stop),\"_"+stop_id+"\"))\n" +
      //" ?stop gtfs:agency ?agency.\n" +
      //" filter(strends(str(?agency),\"_"+agency_id+"\"))\n" +
      " ?agency foaf:name ?agencyName.\n" +
      " ?stop foaf:name ?name.\n" +
      " ?stop a ?class.\n" +
      " ?class rdfs:subClassOf ?mclass.\n" +
      " ?mclass rdfs:subClassOf km4c:Service. \n" +
      "}";
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, query);
    //ServiceMap.println(query);
    long start = System.nanoTime();
    TupleQueryResult result = tq.evaluate();
    ServiceMap.logQuery(query, "API-shortest-path-find-stop", "virtuoso", "", System.nanoTime()-start);
    
    while(result.hasNext()) {
      BindingSet binding = result.next();
      agencyUri = binding.getValue("agency").stringValue();
      if(agencyUri.endsWith("_"+agency_id)) {
        stopUri = binding.getValue("stop").stringValue();
        stopName = binding.getValue("name").stringValue();
        agencyName = binding.getValue("agencyName").stringValue();
        String _class = binding.getValue("class").stringValue().replace("http://www.disit.org/km4city/schema#", "");
        String macroClass = binding.getValue("mclass").stringValue().replace("http://www.disit.org/km4city/schema#", "");
        serviceType = macroClass+"_"+_class;
        break;
      }
    }
    JSONObject stop = new JSONObject();
    stop.put("stop_uri", stopUri);
    stop.put("stop_name", stopName);
    stop.put("agencyName", agencyName);
    stop.put("agencyUri", agencyUri);
    stop.put("serviceType", serviceType);
    return stop;
  }

  static synchronized public String getTplAgencyPrefix(RepositoryConnection con, String agency_id) throws Exception {
    if(tplAgencies==null) {
      tplAgencies = new HashMap<>();
      TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, "SELECT * { ?a a gtfs:Agency. }");
      TupleQueryResult result = tq.evaluate();
   
      while(result.hasNext()) {
        BindingSet binding = result.next();
        String[] a = binding.getValue("a").stringValue().split("_Agency_");
        tplAgencies.put(a[1],a[0]);
      }
      ServiceMap.println(tplAgencies);
    }
    
    return tplAgencies.get(agency_id);    
  }
  
  static synchronized public void resetTplAgencies() {
    tplAgencies=null;
  }

  static public String makeServiceType(String category, String type) {
    return category.replace("http://www.disit.org/km4city/schema#", "")+"_"+type.replace("http://www.disit.org/km4city/schema#", "");
  }
  
  static public String getServicePhotos(String uri) throws IOException,SQLException {
    return getServicePhotos(uri, "");
  }

  static public void updatedPhotos() {
    synchronized(ServiceMap.class) {
      photosAvailable = null;
    }
  }

  static public String getServicePhotos(String uri, String type) throws IOException,SQLException {
    synchronized(ServiceMap.class) {
      if(photosAvailable == null) {
        photosAvailable = new HashMap<>();
        Connection connection = ConnectionPool.getConnection();
        PreparedStatement st = connection.prepareStatement("SELECT DISTINCT serviceUri FROM ServicePhoto WHERE status='validated'");
        ResultSet rs = st.executeQuery();
        while(rs.next()) {
          photosAvailable.put(rs.getString("serviceUri"),"");
        }
        st.close();
        connection.close();
      }
    }
    if(photosAvailable!= null && !photosAvailable.containsKey(uri)) {
      //ServiceMap.println("no photo for "+uri);
      return "[]";
    }
    String json = "[";
    Connection connection = ConnectionPool.getConnection();
    String baseApiUrl = Configuration.getInstance().get("baseApiUrl", "");
    if(!"".equals(type) && !type.endsWith("/"))
      type += "/";
    
    try {
      int i=0;
      PreparedStatement st = connection.prepareStatement("SELECT file FROM ServicePhoto WHERE serviceUri=? AND status='validated'");
      st.setString(1, uri);
      ResultSet rs = st.executeQuery();
      while(rs.next()) {
        json += (i>0?",":"")+"\""+baseApiUrl+"v1/photo/"+type+rs.getString("file")+"\"";
        i++;
      }
      json +="]";
      st.close();
      connection.close();
    } catch (SQLException ex) {
      ServiceMap.notifyException(ex);
    }
    return json;
  }
  
  static public float[] getAvgServiceStars(String serviceUri) throws IOException,SQLException {
    float[] r = new float[2];
    r[0]=0;
    r[1]=0;
    Connection connection = ConnectionPool.getConnection();
    try {
      PreparedStatement st = connection.prepareStatement("SELECT avg(stars) as avgStars, count(*) as count FROM ServiceStars WHERE serviceUri=?");
      st.setString(1, serviceUri);
      ResultSet rs = st.executeQuery();
      if(rs.next()) {
        r[0] = rs.getFloat("avgStars");
        r[1] = rs.getInt("count");
      }
      st.close();
      connection.close();
    } catch (SQLException ex) {
      ServiceMap.notifyException(ex);
    }
    return r;
  }

  static public int getServiceStarsByUid(String serviceUri, String uid) throws IOException,SQLException {
    int stars = 0;
    Connection connection = ConnectionPool.getConnection();
    try {
      PreparedStatement st = connection.prepareStatement("SELECT stars FROM ServiceStars WHERE serviceUri=? AND uid=?");
      st.setString(1, serviceUri);
      st.setString(2, uid);
      ResultSet rs = st.executeQuery();
      if(rs.next()) {
        stars = rs.getInt("stars");
      }
      st.close();
      connection.close();
    } catch (SQLException ex) {
      ServiceMap.notifyException(ex);
    }
    return stars;
  }
  
  static public String getServiceComments(String serviceUri) throws IOException,SQLException {
    String json = "[";
    Connection connection = ConnectionPool.getConnection();
    String baseApiUrl = Configuration.getInstance().get("baseApiUrl", "");
    try {
      int i=0;
      PreparedStatement st = connection.prepareStatement("SELECT comment, timestamp FROM ServiceComment WHERE serviceUri=? AND status='validated' ORDER BY timestamp");
      st.setString(1, serviceUri);
      ResultSet rs = st.executeQuery();
      while(rs.next()) {
        json += (i>0?",":"")+"{\"text\":\""+escapeJSON(rs.getString("comment"))+"\", \"timestamp\":\""+rs.getString("timestamp")+"\"}";
        i++;
      }
      json +="]";
      st.close();
      connection.close();
    } catch (SQLException ex) {
      ServiceMap.notifyException(ex);
    }
    return json;
  }
  
  public static String fixWKT(String wkt) {
    return wkt.replace("((", "(").replace("))", ")");
  }
  
  public static String makeLOGUri(String uri) {
    Configuration conf=Configuration.getInstance();
    String logEndPoint = conf.get("logEndPoint","http://log.disit.org/service/?sparql=http://192.168.0.207:8080/ServiceMap/sparql&uri=");

    return logEndPoint+uri;
  }
    
  public static String cleanCategories(String categorie) {
    if (categorie != null && !"".equals(categorie)) {
      String[] arrayCategorie = categorie.split(";");
      categorie = "";
      for(int i=0; i<arrayCategorie.length; i++) {
        String v = arrayCategorie[i].trim();
        if(v.equals(""))
          arrayCategorie[i]=null;
        else {
          if(i!=0)
            categorie += ";"+v;
          else
            categorie += v;
        }
      }
    }
    return categorie;
  }
  
  private static String[] HEADERS_TO_TRY = null;
  /*{ 
      "X-Forwarded-For",
      "Proxy-Client-IP",
      "WL-Proxy-Client-IP",
      "HTTP_X_FORWARDED_FOR",
      "HTTP_X_FORWARDED",
      "HTTP_X_CLUSTER_CLIENT_IP",
      "HTTP_CLIENT_IP",
      "HTTP_FORWARDED_FOR",
      "HTTP_FORWARDED",
      "HTTP_VIA",
      "REMOTE_ADDR" };*/

  public static String getClientIpAddress(HttpServletRequest request) {
    Configuration conf = Configuration.getInstance();
    String proxyHeaders = conf.get("ipaddrProxyHeaders", null);
    if(proxyHeaders!=null) {
      if(HEADERS_TO_TRY==null) {
        HEADERS_TO_TRY = proxyHeaders.split(";");
      }
      for (String header : HEADERS_TO_TRY) {
          String ip = request.getHeader(header);
          if (ip != null && ip.length() != 0 && !"unknown".equalsIgnoreCase(ip) && !"127.0.0.1".equals(ip)) {
            //ServiceMap.println("IPAddr from "+header+" "+ip);
            return ip;
          }
      }
    }
    //ServiceMap.println("IPAddr from request "+request.getRemoteAddr());
    return request.getRemoteAddr();
  }
  
  public static String[] parsePosition(String position) throws Exception {
    if(position==null)
      return null;
    String[] latLng = position.split(";");
    if(latLng.length==2)
      return latLng;
    if(!position.startsWith("http://")) {
      return null;
    }
    latLng = new String[2];
    Map<String,String> info = getServiceInfo(position,"en");
    if(info.isEmpty())
      return null;
    latLng[0] = info.get("lat");
    latLng[1] = info.get("long");
    return latLng;
  }
  
  public static String[] findTime(String s) {
    String[] times=new String[2];
    if(s==null || s.isEmpty())
      return times;
    Pattern r = Pattern.compile("[^0-9]([0-9]?[0-9])[\\.:,]([0-5][0-9])\\s*-\\s*([0-9]?[0-9])[\\.:,]([0-5][0-9])[^0-9]");
    Matcher m = r.matcher(" "+s+" ");
    int pos=0;
    //ServiceMap.println("-- "+s);
    int i=0;
    if(m.find(pos)) {
      //ServiceMap.println(">> Found: " + m.group(1)+":"+m.group(2)+"-"+m.group(3)+":"+m.group(4));
      String c = m.group(1);
      if(c.length()<2)
        c="0"+c;
      times[i] = c+":"+m.group(2);
      if(times[i].compareTo("00:00")>=0 && times[i].compareTo("23:59")<=0) {
        c = m.group(3);
        if(c.length()<2)
          c="0"+c;
        times[i+1] = c+":"+m.group(4);
        if(times[i+1].compareTo("00:00")>=0 && times[i+1].compareTo("23:59")<=0) {
          i += 2;
        } else
          times[i+1]=null;
      } else
        times[i]=null;
    }
    if(i==0) {
      r = Pattern.compile("[^0-9]([0-9]?[0-9])[\\.:,]([0-5][0-9])[^0-9]");
      m = r.matcher(" "+s+" ");
      if(m.find()) {
        //ServiceMap.println(">> Found: " + m.group(1)+":"+m.group(2));
        String c = m.group(1);
        if(c.length()<2)
          c="0"+c;
        times[i] = c+":"+m.group(2);
        if(!(times[i].compareTo("00:00")>=0 && times[i].compareTo("23:59")<=0)) {
          times[i] = null;
        }
      }
    }
    return times;
  }
  
  public static boolean validateUID(String uid) {
    if(uid==null || uid.length()<4)
      return false;
    if(uid.matches("[0-9a-zA-Z]*"))
      return true;
    return false;
  }
  
  public static String replaceHTMLEntities(String s) {
    return s.replace("&agrave;", "à")
            .replace("&egrave;", "è")
            .replace("&ugrave;", "ù")
            .replace("&igrave;", "ì")
            .replace("&ograve;", "ò")
            .replace("&eacute;", "é")
            .replace("&aacute;", "á")
            .replace("&eacuto;", "é")
            .replace("&aacuto;", "á");
  }
  
  public static Connection getRTConnection() throws Exception {
    Configuration conf = Configuration.getInstance();
    Class.forName("org.apache.phoenix.jdbc.PhoenixDriver");
    //Class.forName("org.apache.phoenix.queryserver.client.Driver");
    return DriverManager.getConnection(conf.get("phoenixJDBC", "jdbc:phoenix:192.168.0.118,192.168.0.124,192.168.0.129:2181:/hbase")); //jdbc:phoenix:thin:url=http://192.168.0.228:8765
  }
  
  public static Connection getRTConnection2() throws Exception {
    Configuration conf = Configuration.getInstance();
    Class.forName("org.apache.phoenix.jdbc.PhoenixDriver");
    //Class.forName("org.apache.phoenix.queryserver.client.Driver");
    return DriverManager.getConnection(conf.get("phoenixJDBC2", "jdbc:phoenix:192.168.0.228,192.168.0.232,192.168.0.233:2281:/hbase-unsecure")); //jdbc:phoenix:thin:url=http://192.168.0.228:8765
  }
  
  public static boolean checkIP(String IPAddr, String requestType) throws Exception {
    Connection connection = ConnectionPool.getConnection();
    Configuration conf = Configuration.getInstance();
    boolean ret=false;
    String ipNetworks = conf.get("ipNetworkPrefixes", null);
    String ipAddrOrNetw = IPAddr;
    if(ipNetworks!=null) {
      String[] prefixes = ipNetworks.split(";");
      for(String pfx : prefixes) {
        if(!pfx.trim().isEmpty() && IPAddr.startsWith(pfx.trim())) {
          ipAddrOrNetw = pfx;
          break;
        }
      }
    }
    String maxReqs = conf.get("maxReqsPerDayPerIP."+requestType+"."+ipAddrOrNetw, null);
    if(maxReqs==null) {
      if(IPAddr.equals("127.0.0.1") || IPAddr.startsWith("192.168."))
        maxReqs = "-1";
      else
        maxReqs = conf.get("maxReqsPerDayPerIP."+requestType, "-1");
    }
    String maxRslts = conf.get("maxResultsPerDayPerIP."+requestType+"."+ipAddrOrNetw, null);
    if(maxRslts==null) {
      if(IPAddr.equals("127.0.0.1") || IPAddr.startsWith("192.168."))
        maxRslts = "-1";
      else
        maxRslts = conf.get("maxResultsPerDayPerIP."+requestType, "-1");
    }
    int maxRequests = Integer.parseInt(maxReqs);
    int maxResults = Integer.parseInt(maxRslts);
    try {
      PreparedStatement st = connection.prepareStatement("SELECT doneCount,resultsCount FROM ServiceLimit WHERE ipaddr=? AND date=current_date() AND requestType=?");
      st.setString(1, IPAddr);
      st.setString(2, requestType);
      ResultSet rs = st.executeQuery();
      if(rs.next()) {
        int count = rs.getInt("doneCount");
        int results = rs.getInt("resultsCount");
        Statement update=connection.createStatement();
        if((maxRequests>=0 && count>=maxRequests) || (maxResults>=0 && results>=maxResults)) {
          update.executeUpdate("UPDATE ServiceLimit SET limitedCount=limitedCount+1 WHERE ipaddr='"+IPAddr+"' AND date=current_date() AND requestType='"+requestType+"'");
          ret=false;
        } else {
          update.executeUpdate("UPDATE ServiceLimit SET doneCount=doneCount+1 WHERE ipaddr='"+IPAddr+"' AND date=current_date() AND requestType='"+requestType+"'");
          ret=true;          
        }
        update.close();
      } else {
        try {
          Statement insert=connection.createStatement();
          insert.executeUpdate("INSERT INTO ServiceLimit(ipaddr,requestType,date,doneCount) VALUES('"+IPAddr+"','"+requestType+"',current_date(),1)");
          insert.close();
          ret=true;
        } catch(SQLException ex) {
          // se fallisce inserimento per chiave duplicata fa update
          Statement update=connection.createStatement();          
          update.executeUpdate("UPDATE ServiceLimit SET doneCount=doneCount+1 WHERE ipaddr='"+IPAddr+"' AND date=current_date() AND requestType='"+requestType+"'");
          if(update.getUpdateCount()==0)
            ServiceMap.notifyException(ex,"update failed");
          update.close();
          ret=true;
        }
      }
      st.close();
      connection.close();
    } catch (SQLException ex) {
      connection.close();
      ServiceMap.notifyException(ex);
      ret=true;
    }
    return ret;
  }

  public static void updateResultsPerIP(String IPAddr, String requestType, int results) throws Exception {
    Connection connection = ConnectionPool.getConnection();
    try {
      Statement update=connection.createStatement();
      update.executeUpdate("UPDATE ServiceLimit SET resultsCount=resultsCount+"+results+" WHERE ipaddr='"+IPAddr+"' AND date=current_date() AND requestType='"+requestType+"'");
      if(update.getUpdateCount()==0) { //se check fatto prima di mezzanotte e inserimento fatto dopo, la riga del giorno nuovo non c'e'
        Statement insert=connection.createStatement();
        insert.executeUpdate("INSERT INTO ServiceLimit(ipaddr,requestType,date,doneCount,resultsCount) VALUES('"+IPAddr+"','"+requestType+"',current_date(),1,"+results+")");
        insert.close();
      }
      update.close();
      connection.close();
    } catch (SQLException ex) {
      connection.close();
      ServiceMap.notifyException(ex);
    }
  }

  public static void notifyException(Throwable exc) {
    notifyException(exc, null);
  }
  
  public static void notifyException(Throwable exc, String details) {
    Configuration conf = Configuration.getInstance();

    String url = conf.get("notificatorRestInterfaceUrl", null);
    if(url==null || url.trim().isEmpty()) {
      String notifyExceptionTo = conf.get("notifyExceptionTo", null);
      if(notifyExceptionTo==null || notifyExceptionTo.trim().isEmpty()) {
        System.out.println(new Date()+" notifyException disabled");
        if(exc!=null)
          exc.printStackTrace();
        return;
      } else {
        System.out.println(new Date()+" notifyExceptionTo "+notifyExceptionTo);
        String subj = conf.get("notityExceptionSubj", "[SMTEST]");
        if(exc!=null)
          exc.printStackTrace();
        if(details!=null)
          System.out.println(details);
        sendEmail(notifyExceptionTo, subj+(exc!=null ? " Exception "+exc.getClass().getSimpleName() : " ERROR"), exceptionMessage(exc, details), "text/plain");
        return;
      }
    }
    if(exc!=null)
      exc.printStackTrace();
    if(details!=null)
      System.out.println(details);
    String charset = java.nio.charset.StandardCharsets.UTF_8.name();
    String apiUsr = conf.get("notificatorRestInterfaceUsr", "usr");
    String apiPwd = conf.get("notificatorRestInterfacePwd", "pwd");
    String appName = conf.get("notificatorRestInterfaceAppName", "ServiceMapTest");
    String operation = "notifyEvent";
    String generatorOriginalName = "Error";
    String generatorOriginalType = "Exception";
    String containerName = "Exceptions";
    String eventType = "Exception";
    String furtherDetails = exceptionMessage(exc, details);

    Calendar date = new GregorianCalendar();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    String eventTime = sdf.format(date.getTime());
    String params = null;

    URL obj = null;
    HttpURLConnection con = null;
    try {
      obj = new URL(url);
      con = (HttpURLConnection) obj.openConnection();

      con.setRequestMethod("POST");
      con.setRequestProperty("Accept-Charset", charset);
      con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded;charset=" + charset);

      params = String.format("apiUsr=%s&apiPwd=%s&appName=%s&operation=%s&generatorOriginalName=%s&generatorOriginalType=%s&containerName=%s&eventType=%s&eventTime=%s&furtherDetails=%s",
         URLEncoder.encode(apiUsr, charset),
         URLEncoder.encode(apiPwd, charset),
         URLEncoder.encode(appName, charset),
         URLEncoder.encode(operation, charset),
         URLEncoder.encode(generatorOriginalName, charset),
         URLEncoder.encode(generatorOriginalType, charset),
         URLEncoder.encode(containerName, charset),
         URLEncoder.encode(eventType, charset),
         URLEncoder.encode(eventTime, charset),
         URLEncoder.encode(furtherDetails, charset));

      // Questo rende la chiamata una POST
      con.setDoOutput(true);
      DataOutputStream wr = null;

      wr = new DataOutputStream(con.getOutputStream());
      wr.writeBytes(params);
      wr.flush();
      wr.close();

      int responseCode = con.getResponseCode();
      String responseMessage = con.getResponseMessage();
      if(responseCode!=200) {
        System.out.println(new Date()+" notifyEvent "+responseCode+" "+responseMessage);
        if(exc!=null)
          exc.printStackTrace();
      }
    } catch (IOException ex) {
      ex.printStackTrace();
      System.out.println("failed exception notification");
      if(exc!=null)
        exc.printStackTrace();
    }
  }
  
  public static String exceptionMessage(Throwable exp, String details) {
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    Date data_attuale = new Date();
    String data_fixed = df.format(data_attuale);
    String msgBody = "ERROR ";
    if(exp!=null) {
      msgBody = "Exception: " + exp.getClass().getSimpleName();
    }
    msgBody += " exception thrown at " + data_fixed;
    msgBody += "\nError Details:\n";
    if(details!=null)
      msgBody += details+"\n";
/*    msgBody += "\nException: " + msg;
    if (exp.getCause() != null) {
      msg = exp.getCause().getMessage();
      if (msg != null) {
        msg = msg.replace("\n", " ");
      }
      msgBody += "\nCause: " + msg;
    }
    msgBody += "\nJava Class: " + className;
    msgBody += "\nDate: " + data_fixed;*/
    if(exp!=null) {
      StringWriter sw = new StringWriter();
      PrintWriter pw = new PrintWriter(sw);
      exp.printStackTrace(pw);
      String sStackTrace = sw.toString(); // stack trace as a string
      msgBody += sStackTrace;
    }
    return msgBody;
  }
  
  public static void println(Object msg) {
    Configuration conf = Configuration.getInstance();
    if(conf.get("debug", "true").equalsIgnoreCase("true")){
      StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();
      System.out.println("DEBUG "+new Date()+" ["+Thread.currentThread().getName()+":"+
              stackTraceElements[2].getClassName()+"."+
              stackTraceElements[2].getMethodName()+"()] "+msg);
    }
  }
  
  public static Map<String,String> getTplRealPassageTimes(String agencyName, String busStopId) throws Exception {
    Configuration conf = Configuration.getInstance();
    String agencies = conf.get("tplRTEnabled", "Siena Mobilità");
    if(agencies!=null) {
      if(agencyName!=null && !agencyName.isEmpty() && agencies.contains(agencyName)) {
        String areaId = conf.get("tplRT.areaId."+agencyName.replace(" ", ""), "SIENA");
        Connection conn = null;
        try {
          conn = getRTConnection2();
          Statement st = conn.createStatement();
          String now = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
          ResultSet rs = st.executeQuery("SELECT \"busStopId\",\"lastUpdate\",\"lineLabel\",\"theoreticalPassageTime\", \"realPassageTime\" FROM \"tiemmeBusStopForecasts\" WHERE \"areaId\"='"+areaId+"' AND \"busStopId\"='"+busStopId+"' AND \"realPassageTime\">='"+now+"'ORDER BY \"lastUpdate\" DESC LIMIT 100");
          Map<String,String> r = new HashMap<>();
          while(rs.next()) {
            String lineLabel = rs.getString("lineLabel").toUpperCase();
            String theoreticalTime = rs.getString("theoreticalPassageTime");
            String realTime = rs.getString("realPassageTime").split(" ")[1]; //get only the time
            if(!r.containsKey(lineLabel+"/"+theoreticalTime))
              r.put(lineLabel+"/"+theoreticalTime, realTime);
          }
          ServiceMap.println(busStopId+ " --> "+r.toString());
          rs.close();
          st.close();
          conn.close();
          return r;
        } catch(Exception e) {
          notifyException(e,"busStopId: "+busStopId+" agency: "+agencyName+" areaId: "+areaId);
          if(conn!=null)
            conn.close();
        }
      }
    }
    return null;
  }
  
  public static JSONObject getStopsFromTo(RepositoryConnection con, String srcStopUri, String dstStopUri, String tripId, String time, String date) throws Exception {
    boolean addChecks = Configuration.getInstance().get("shortestPathsTplChecks","true").equals("true");
    JSONArray stops = new JSONArray();
    String wkt = "";
    String query="select distinct ?s ?name ?lat ?lon ?class ?mclass ?agency ?agencyName ?time ?ss ?trip ?x {\n" +
      "?st1 a gtfs:StopTime.\n" +
      "?st1 gtfs:stop <"+srcStopUri+">.\n" +
      (addChecks ? "?st1 gtfs:arrivalTime \""+time+"\".\n" : "") +
      "?st1 gtfs:stopSequence ?ss1.\n" +
      "?st1 gtfs:trip ?trip.\n" +
      "?st2 a gtfs:StopTime.\n" +
      "?st2 gtfs:stop <"+dstStopUri+">.\n" +
      "?st2 gtfs:trip ?trip.\n" +
      "FILTER(STRENDS(STR(?trip),\"_"+tripId+"\"))" +
      "?st2 gtfs:stopSequence ?ss2.\n" +
      (addChecks ? "?trip gtfs:service/dcterms:date \""+date+"\".\n" : "") +
      "?st gtfs:stop ?s.\n" +
      "?st gtfs:trip ?trip.\n" +
      "?st gtfs:arrivalTime ?time.\n" +
      "?st gtfs:stopSequence ?ss. \n" +
      "FILTER(xsd:int(?ss)>=xsd:int(?ss1))\n" +
      "FILTER(xsd:int(?ss)<=xsd:int(?ss2))\n" +
      "?s foaf:name ?name.\n" +
      "?s geo:lat ?lat.\n" +
      "?s geo:long ?lon.\n" +
      "?s a ?class.\n" +
      "?class rdfs:subClassOf ?mclass.\n" +
      "?mclass rdfs:subClassOf km4c:Service.\n" +
      "?s gtfs:agency ?agency.\n" +
      "?agency foaf:name ?agencyName.\n" +
      "\n" +
      "} order by ?ss";
    //ServiceMap.println(query);
    long start = System.nanoTime();
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, query);
    TupleQueryResult result = tq.evaluate();
    ServiceMap.logQuery(query, "API-shortest-path-find-trip", "virtuoso", "", System.nanoTime()-start);
    String trip = null;
    int id=1;
    while(result.hasNext()) {
      BindingSet binding = result.next();
      
      JSONObject stop = new JSONObject();
      stop.put("serviceUri", binding.getValue("s").stringValue());
      stop.put("name", binding.getValue("name").stringValue());
      stop.put("arrivalTime", binding.getValue("time").stringValue());
      stop.put("agency", binding.getValue("agencyName").stringValue());
      stop.put("agencyUri", binding.getValue("agency").stringValue());
      String _class = binding.getValue("class").stringValue().replace("http://www.disit.org/km4city/schema#", "");
      String macroClass = binding.getValue("mclass").stringValue().replace("http://www.disit.org/km4city/schema#", "");
      stop.put("serviceType", macroClass+"_"+_class);
      
      JSONObject geometry = new JSONObject();
      geometry.put("type","Point");
      JSONArray coords = new JSONArray();
      coords.add(Double.parseDouble(binding.getValue("lon").stringValue()));
      coords.add(Double.parseDouble(binding.getValue("lat").stringValue()));
      geometry.put("coordinates",coords);

      JSONObject feature = new JSONObject();
      feature.put("type", "Feature");
      feature.put("geometry", geometry);
      feature.put("properties", stop);
      feature.put("id", id++);
      trip = binding.getValue("trip").stringValue();
      stops.add(feature);
    }
    result.close();
    if(trip!=null) {
      start=System.nanoTime();
      JSONObject firstGeo = (JSONObject)((JSONObject) stops.get(0)).get("geometry");
      JSONObject lastGeo = (JSONObject)((JSONObject) stops.get(stops.size()-1)).get("geometry");
      String queryTrip = "SELECT ?wkt { <"+trip+"> <http://www.opengis.net/ont/geosparql#hasGeometry>/geo:geometry ?wkt }";
      String tripWKT = null;
      TupleQuery tqq = con.prepareTupleQuery(QueryLanguage.SPARQL, queryTrip);
      TupleQueryResult r = tqq.evaluate();
      if(r.hasNext()) {
        BindingSet binding = r.next();
        tripWKT = binding.getValue("wkt").stringValue();
      }
      r.close();
      if(tripWKT!=null) {
        WKTReader wktReader=new WKTReader();
        Geometry g=wktReader.read(tripWKT);
        Coordinate[] coords = g.getCoordinates();
        JSONArray firstCoord = (JSONArray) firstGeo.get("coordinates");
        JSONArray lastCoord = (JSONArray) lastGeo.get("coordinates");
        Coordinate first = new Coordinate((double)firstCoord.get(0),(double)firstCoord.get(1));
        Coordinate last = new Coordinate((double)lastCoord.get(0),(double)lastCoord.get(1));
        int foundFirst = -1;
        int foundLast = -1;
        //ServiceMap.println(first);
        //ServiceMap.println(last);
        double firstMinDist = 1000.0;
        double lastMinDist = 1000.0;
        for(int i=0 ; i<coords.length; i++) {
          double dFirst = coords[i].distance(first);
          double dLast = coords[i].distance(last);
          //ServiceMap.println(i+":"+coords[i]+":"+coords[i].distance(first)+":"+coords[i].distance(last));
          if(dFirst<firstMinDist) {
            foundFirst = i;
            firstMinDist = dFirst;
          }
          if(dLast<lastMinDist) {
            foundLast = i;
            lastMinDist = dLast;
          }
        }
        //ServiceMap.println("first: "+foundFirst+" last:"+foundLast);
        if(foundFirst>=0 && foundLast>=0) {
          wkt += first.x + " " + first.y +",";
          for(int i=foundFirst+1; i<foundLast; i++) {
            wkt += coords[i].x+" "+coords[i].y+",";
          }
          wkt += last.x+" "+last.y;
        } else {
          throw new Exception("cannot extract WKT "+srcStopUri+" "+dstStopUri+" "+trip);
        }
        ServiceMap.println("wkt time:"+(System.nanoTime()-start)/1000000.0);
      }
    } else {
      ServiceMap.notifyException(null, "Trip not found: "+srcStopUri+","+dstStopUri+","+tripId+","+time+","+date);
    }

    JSONObject sstops = new JSONObject();
    sstops.put("type", "FeatureCollection");
    sstops.put("features", stops);
    sstops.put("wkt", wkt);
    return sstops;
  }
  
  static public String getOsmNodeId(String lat, String lon) throws Exception{
    Configuration conf = Configuration.getInstance();
    Repository repo;
    RepositoryConnection con;
    
    String sparqlEndpoint = conf.get("sparqlOsmEndpoint", "jdbc:virtuoso://192.168.0.208:1111");
    if(sparqlEndpoint.startsWith("http:"))
      repo = new SPARQLRepository(sparqlEndpoint);
    else if(sparqlEndpoint.startsWith("jdbc:virtuoso:")){
      repo = new VirtuosoRepository(sparqlEndpoint, conf.get("sparqlOsmUser", "dba"), conf.get("sparqlOsmPasswd","dba"));
    } else
      throw new Exception("invalid sparqlOsmEndpoint "+sparqlEndpoint);
    
    repo.initialize();
    con = repo.getConnection();
    String query = "select ?n {\n" +
        "?n a km4c:Node.\n" +
        "?n geo:geometry ?g.\n" +
        "filter(bif:st_intersects(?g, bif:st_point("+lon+","+lat+"),0.5))\n" +
        "bind(bif:st_distance(?g,bif:st_point("+lon+","+lat+")) as ?d)\n" +
        "} order by ?d limit 1";
    TupleQuery tq = con.prepareTupleQuery(QueryLanguage.SPARQL, query);
    long start = System.nanoTime();
    TupleQueryResult result = tq.evaluate();
    ServiceMap.logQuery(query, "API-shortest-path-find-osmnode", "virtuoso", "", System.nanoTime()-start);
    String nodeid = null;
    if(result.hasNext()) {
      BindingSet binding = result.next();
      String n=binding.getValue("n").stringValue();
      nodeid=n.substring(40,51).replaceFirst("^0+(?!$)", "");
      ServiceMap.println("nid:"+nodeid+" "+n);
    }
    con.close();
    return nodeid;
  }
  
  public static String getMapDefaultLatLng(ServletRequest request, String def) {
    Configuration conf = Configuration.getInstance();
    ServiceMap.println("servername: "+request.getServerName());
    String m = conf.get(request.getServerName()+".mapDefLatLng", null);
    if(m==null)
      m=conf.get("mapDefLatLng", def);
    return m;
  }

  public static String getMapDefaultZoom(ServletRequest request, String def) {
    Configuration conf = Configuration.getInstance();
    String m = conf.get(request.getServerName()+".mapDefZoom", null);
    if(m==null)
      m=conf.get("mapDefZoom", def);
    return m;
  }

  public static String getCurrentTimezoneOffset() {
    TimeZone tz = TimeZone.getDefault();  
    Calendar cal = GregorianCalendar.getInstance(tz);
    int offsetInMillis = tz.getOffset(cal.getTimeInMillis());

    String offset = String.format("%02d:%02d", Math.abs(offsetInMillis / 3600000), Math.abs((offsetInMillis / 60000) % 60));
    offset = (offsetInMillis >= 0 ? "+" : "-") + offset;

    return offset;
}   
}
