<%@ page import="java.sql.*, javax.naming.*, javax.sql.DataSource" %>
<%@ page import="java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
  <head>
    <title>User Information</title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
  </head>
  <body>
    <div class="container">
      <h2>User Information</h2>
      <form method="get">
        <label for="filter">Filter by name:</label>
        <input type="text" id="filter" name="filter" value="<%= request.getParameter("filter") != null ? request.getParameter("filter") : "" %>">
        <input type="submit" value="Filter">
      </form>
      <table>
        <tr>
          <th>Name</th>
          <th>Email</th>
          <th>Etc</th>
        </tr>
        <% 
          String filter = request.getParameter("filter");
          Connection conn = null;
          PreparedStatement stmt = null;
          ResultSet rs = null;
          try {
            Context initContext = new InitialContext();
            Context envContext  = (Context)initContext.lookup("java:/comp/env");
            DataSource ds = (DataSource)envContext.lookup("jdbc/postgresql");
            conn = ds.getConnection();

            String sql = "SELECT name, email, etc FROM user_info";
            if (filter != null && !filter.isEmpty()) {
              sql += " WHERE name LIKE ?";
            }

            stmt = conn.prepareStatement(sql);
            if (filter != null && !filter.isEmpty()) {
              stmt.setString(1, "%" + filter + "%");
            }

            rs = stmt.executeQuery();

            while (rs.next()) {
              String name = rs.getString("name");
              String email = rs.getString("email");
              String etc = rs.getString("etc");
        %>
        <tr>
          <td><%= name %></td>
          <td><%= email %></td>
          <td><%= etc %></td>
        </tr>
        <% 
            }
          } catch (Exception e) {
            out.println("Error: " + e.getMessage());
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            out.println(sw.toString());
          } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignore) {}
            if (stmt != null) try { stmt.close(); } catch (SQLException ignore) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignore) {}
          }
        %>    
      </table>
    </div>
  </body>
</html>
