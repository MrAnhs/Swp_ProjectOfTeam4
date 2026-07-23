<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.io.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>JSP Diagnostic</title>
</head>
<body>
    <h3>Diagnostic Info</h3>
    <p>Real Path of Webapp Root: <strong><%= request.getServletContext().getRealPath("/") %></strong></p>
    <p>Current Time: <strong><%= new java.util.Date() %></strong></p>
    <h4>File schedule-management.jsp content lines 1020-1045:</h4>
    <pre>
<%
    String path = request.getServletContext().getRealPath("/WEB-INF/views/admin/scheduling/schedule-management.jsp");
    File f = new File(path);
    if (f.exists()) {
        BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(f), "UTF-8"));
        String line;
        int lineNum = 1;
        while ((line = br.readLine()) != null) {
            if (lineNum >= 1020 && lineNum <= 1045) {
                out.println(lineNum + ": " + line.replace("<", "&lt;").replace(">", "&gt;"));
            }
            lineNum++;
        }
        br.close();
    } else {
        out.println("File not found at: " + path);
    }
%>
    </pre>
</body>
</html>
