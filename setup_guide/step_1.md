

## 구축 과정

### K8S 구축 (Master Node, Worker Node)

#### 1. Hostname 변경

```bash
sudo hostnamectl set-hostname [HOST NAME]
```



#### 2. Git 저장소 가져오기

```bash
sudo yum install git -y
```

``` 
git clone https://github.com/gweowe/3-tier-architecture-project.git
```

```bash
cd ./3-tier-architecture-project
```



#### 3. 구축 스크립트 실행

##### Master Node

```bash
chmod 755 ./k8s_install_script/master_node.sh
```

```bash
vi ./k8s_install_script/master_node.sh
```

```
# 41 line edit
sudo kubeadm init --control-plane-endpoint=[DOMAIN OR IP] --pod-network-cidr=[POD CIDR]
```

```bash
./k8s_install_script/master_node.sh
```

##### Worker Node 1 ~ 3

```bash
chmod 755 ./k8s_install_script/worker_node.sh
```

```bash
./k8s_install_script/worker_node.sh
```



#### 4. join 작업 수행

##### Master Node

```bash
kubeadm token create --print-join-command
```

##### Worker Node 1 ~ 3

```bash
[INSERT THE RESULT OUTPUT FROM THE MASTER NODE]
```



#### 5. 구축 상태 확인

```bash
kubectl get node
```

##### output:

```
NAME            STATUS   ROLES           AGE     VERSION
master-node-1   Ready    control-plane   3m45s   v1.28.11
worker-node-1   Ready    <none>          3m1s    v1.28.11
worker-node-2   Ready    <none>          2m53s   v1.28.11
worker-node-3   Ready    <none>          3m1s    v1.28.11
```

만약 `STATUS`가 `NotReady`일 경우 Node 정보에서 Conditions 항목 확인하여 Troubleshooting 진행

```bash
kubectl describe node [NODE NAME]
```



#### 6. NodePort 범위 재설정

##### master-node-1

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

###### kube-apiserver.yaml

```
# -------------------- 생략 --------------------

spec:
  containers:
  - command:
    - kube-apiserver
    - --service-node-port-range=30000-40000
    
# -------------------- 생략 --------------------
```



----------------

### 3-Tier 구축을 위한 사전 작업

#### 1. Base Image 실행

##### Nginx

```bash
docker run -d --name nginx -p 80:80 -e TZ=Asia/Seoul nginx:1.27.0
```

##### Tomcat

```bash
docker run -d --name tomcat -p 8080:8080 -e TZ=Asia/Seoul tomcat:10.1.24
```

##### PostgreSQL

```bash
docker run -d --name postgresql -p 5432:5432 -e POSTGRES_PASSWORD=gweowe123 -e TZ=Asia/Seoul postgres:16.3
```



#### 2. 3-Tier 설정 파일 수정 및 백업

##### Nginx

```bash
docker exec -it nginx /bin/bash
```

```bash
apt-get update
```

```bash
apt-get install vim -y
```

```bash
vi ~/.vimrc
```

###### .vimrc

```
set expandtab
set tabstop=2
```

```bash
vi /etc/nginx/conf.d/default.conf
```

###### default.conf

```
# -------------------- 생략 --------------------

	location ~ \.(css|js|jpg|jpeg|gif|png|jsp)$ {
								proxy_pass http://master-node-1.gweowe.com:38080;
								proxy_set_header X-Real-IP $remote_addr;
								proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
								proxy_set_header Host $http_host;
	}

# -------------------- 생략 --------------------
```

```bash
nginx -s reload
```

```bash
exit
```

```bash
docker cp nginx:/etc/nginx/ ./nginx/conf/
```

```bash
docker cp nginx:/usr/share/nginx/ ./nginx/data/
```

##### Tomcat

```bash
docker exec -it tomcat /bin/bash
```

```bash
apt-get update
```

```bash
apt-get install vim -y
```

```bash
vi ~/.vimrc
```

###### .vimrc

```
set expandtab
set tabstop=2
```

```bash
wget https://jdbc.postgresql.org/download/postgresql-42.7.3.jar
```

```bash
mv ./postgresql-42.7.3.jar /usr/local/tomcat/lib/
```

```bash
vi /usr/local/tomcat/conf/context.xml
```

###### context.xml

```
# -------------------- 생략 --------------------

<Context>
	<Resource name="jdbc/postgresql"
						auth="Container"
						type="javax.sql.DataSource"
						driverClassName="org.postgresql.Driver"
						loginTimeout="10"
						maxWait="5000"
						username="postgres"
						password="[PSQL USER PASSWORD]"
						url="jdbc:postgresql://master-node-1.gweowe.com:35432/user_data" />
</Context>
  
# -------------------- 생략 --------------------
```

```bash
vi /usr/local/tomcat/conf/web.xml
```

###### web.xml

```
<web-app>

# -------------------- 생략 --------------------

	<resource-ref>
		<description>PGSQL DB Connection</description>
		<res-ref-name>jdbc/postgresql</res-ref-name>
		<res-type>javax.sql.DataSource</res-type>
		<res-auth>Container</res-auth>
	</resource-ref>
    
# -------------------- 생략 --------------------
</web-app>
```

```bash
mkdir /usr/local/tomcat/webapps/ROOT
```

```bash
vi /usr/local/tomcat/webapps/ROOT/user.jsp
```

###### user.jsp

```
<%@ page import="java.sql.*, javax.naming.*, javax.sql.DataSource" %>
<%@ page import="java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
  <head>
    <title>User Information</title>
    <style>
      table {
        width: 100%;
        border-collapse: collapse;
      }
      table, th, td {
        border: 1px solid black;
      }
      th, td {
        padding: 8px;
        text-align: left;
      }
      th {
        background-color: #f2f2f2;
      }
    </style>
  </head>
  <body>
    <h2>User Information</h2>
    <form method="get">
      <label for="filter">Filter by name:</label>
      <input type="text" id="filter" name="filter" value="<%= request.getParameter("filter") != null ? request.getParameter("filter") : "" %>">
      <input type="submit" value="Filter">
    </form>
    <br>
    <table>
      <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Number</th>
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

          String sql = "SELECT name, email, number, etc FROM user_info";
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
            String number = rs.getString("number");
            String etc = rs.getString("etc");
      %>
      <tr>
        <td><%= name %></td>
        <td><%= email %></td>
        <td><%= number %></td>
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
  </body>
</html>
```

```bash
exit
```

```bash
docker restart tomcat
```

```
docker cp tomcat:/usr/local/tomcat/ ./tomcat/
```

##### PostgreSQL

```bash
docker exec -it postgresql /bin/bash
```

```bash
apt-get update
```

```bash
apt-get install vim -y
```

```bash
vi ~/.vimrc
```

###### .vimrc

```
set expandtab
set tabstop=2
```

```bash
vi /var/lib/postgresql/data/pg_hba.conf
```

###### pg_hba.conf

```
# -------------------- 생략 --------------------

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust

# -------------------- 생략 --------------------
```

```bash
psql -U postgres
```

```bash
CREATE DATABASE user_data;
```

```bash
\c user_data
```

```bash
CREATE TABLE user_info (
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    number VARCHAR(255) NOT NULL,
    ETC VARCHAR(255) NULL
);
```

```bash
INSERT INTO user_info (name, email, number, etc)
VALUES ('', '', '', '');
```

```bash
exit
```

```bash
exit
```

```bash
docker cp postgresql:/var/lib/postgresql/ ./postgresql/
```



#### 4. 설정 파일 이동

```bash
scp -r ./nginx root@[WORKER NODE 1 IP]:/
```

`module`을 옮기지 못했다는 에러가 발생하나, 해당 부분에 대한 조치 예정이므로 무시

```bash
scp -r ./tomcat root@[WORKER NODE 2 IP]:/
```

```bash
scp -r ./postgresql root@[WORKER NODE 3 IP]:/
```



----------------

### 3-Tier 배포

#### 1. Storage Class 생성

```bash
kubectl apply -f ./yaml/storage_class.yaml
```



#### 2. Nginx 배포

```bash
kubectl apply -f ./yaml/nginx.yaml
```

```bash
kubectl exec -it [NGINX POD NAME] /bin/bash
```

```bash
ln -s /usr/lib/nginx/modules /etc/nginx/modules
```

```bash
exit
```



#### 3. Tomcat 배포

```bash
kubectl apply -f ./yaml/tomcat.yaml
```



#### 4. Postgresql 배포

```bash
kubectl apply -f ./yaml/postgresql.yaml
```

(3Tier 연결은 확인되었으나 Docker에서 생성한 PostgreSQL의 Database가 사라지는 문제 발생)
