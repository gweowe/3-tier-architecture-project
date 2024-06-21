# 3tier-architecture-project

## 개요

3 Tier Architecture 구성을 시작으로 자체적으로 요구사항을 제시하여 고도화 예정





## 요구사항

--------------

#### 1회 차 (2024/06/11 ~ 2024/06/30)

1. VCS(Github)를 활용한 관리 필요
2. 인프라 구성도 작성
3. 구축 환경 자율적으로 선택
4. 3-Tier 제품 자율적으로 선택
5. DB에 저장하는 데이터는 개인 임의로 입력
6. Web/WAS/DB 활용에 대한 검증 필요

-------------------------





## 구축 환경

#### 인프라 환경

- 플랫폼: VMware
- 운영체제: CentOS 7
- 구축 방식: Kubernetes



#### Kubernetes 클러스터

- Master Node
  - 대수: 1
  - 사양: 4 CPU, 4GB RAM
- Worker Node
  - 대수: 3
  - 사양: 4CPU, 4GB RAM
- 그 외 세부사항
  - K8S Version: v1.28
  - CNI: Calico
  - Pod CIDR: 10.0.0.0/16
  - Container Runtime: Containerd
  



#### Web

- Name: Nginx
- Version: 1.27.0



#### WAS

- Name: Tomcat
- Version: 10.1.24
- JDK: 21.0.3

- JDBC: Postgres 42.7.3

#### DB

- Name: Postgres
- Version: 16.3.1





## 구성도





## 구축 과정

-----------------------

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

----------------

### 3-Tier 구축 (Nginx, Tomcat, Postgres)

#### 1. Docker Network 생성

```bash
docker network create temp_network
```



#### 2. Base Image 실행

##### Nginx

```bash
docker run -d --name nginx --network temp_network -p 80:80 -e TZ=Asia/Seoul nginx:1.27.0
```

##### Tomcat

```bash
docker run -d --name tomcat --network temp_network -p 8080:8080 -e TZ=Asia/Seoul tomcat:10.1.24
```

##### Postgres

```bash
docker run -d --name postgres --network temp_network -p 5432:5432 -e POSTGRES_PASSWORD=[PASSWORD] -e TZ=Asia/Seoul postgres:16.3
```



#### 3. 3-Tier 연동 작업 수행

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

	location ~ \.(css|js|jpg|jpeg|gif|png|html|jsp)$ {
								proxy_pass http://tomcat:8080;
								proxy_set_header X-Real-IP $remote_addr;
								proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
								proxy_set_header Host $http_host;
	}

# -------------------- 생략 --------------------
```

```bash
nginx -s reload
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
						url="jdbc:postgresql://postgres:5432/user_data" /> # K8S에 올린 후 Postgres의 Pod IP로 변경해야 함
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

##### Postgres

```bash
docker exec -it postgres /bin/bash
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



#### 4. docker container를 image로 올리기

```bash
docker commit -a "gweowe" nginx gweowe/nginx:latest
```

```bash
docker commit -a "gweowe" tomcat gweowe/tomcat:latest
```

```bash
docker commit -a "gweowe" postgres gweowe/postgres:latest
```



#### 5. docker image docker hub에 올리기

```bash
docker push gweowe/nginx:latest
```

```bash
docker push gweowe/tomcat:latest
```

```bash
docker push gweowe/postgres:latest
```
