## 구축 과정

### NFS 서버 구축 (NFS Server)

#### 1. 사전 작업 및 nfs 패키지 설치

```bash
sudo systemctl disable --now firewalld
```

```bash
sudo yum update -y
```

```bash
sudo yum install nfs-utils -y
```



#### 2. nfs 서비스 실행

```bash
sudo systemctl enable --now rpcbind
```

```bash
sudo systemctl enable --now nfs-server
```



#### 3. Mount를 위해 Git Clone

```bash
git clone https://github.com/gweowe/3-tier-architecture-project.git
```



#### 4. 공유 설정

```bash
sudo vi /etc/exports
```

##### exports

```
[GIT DERECTORY PATH] [SHARE SERVER CIDR](rw,no_root_squash,sync)

# ex)
# /home/nfs/3-tier-architecture-project 1.1.0.0/24(rw,no_root_squash,sync)
```



#### 5. 설정 적용 및 확인

```bash
sudo exportfs -ra
```

```bash
sudo exportfs -v
```



------

### PV 재설정 (Client Server)

#### 1. yaml 파일 수정 

`pv`를 `local`에서 `nfs`로 변경

##### Nginx

```bash
vi ./yaml/nginx.yaml
```

###### nginx.yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-data-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  nfs:
    path: [GIT CLONE PATH]/nginx/data/nginx
    server: [NFS SERVER IP]
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-conf-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  nfs:
    path: [GIT CLONE PATH]/nginx/conf/nginx
    server: [NFS SERVER IP]

# -------------------- 생략 --------------------
```

##### Tomcat

```bash
vi ./yaml/tomcat.yaml
```

###### tomcat.yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: tomcat-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  nfs:
    path: [GIT CLONE PATH]/tomcat/tomcat
    server: [NFS SERVER IP]
    
# -------------------- 생략 --------------------
```

##### Postgresql

```bash
vi ./yaml/postgresql.yaml
```

###### postgresql.yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgresql-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  nfs:
    path: [GIT CLONE PATH]/postgresql/postgresql
    server: [NFS SERVER IP]
    
# -------------------- 생략 --------------------
```



#### 2. 3-Tier 파일 재배포

##### Nginx

```bash
kubectl delete -f ./yaml/nginx.yaml
```

```bash
kubectl apply -f ./yaml/nginx.yaml
```

##### Tomcat

```bash
kubectl delete -f ./yaml/tomcat.yaml
```

```bash
kubectl apply -f ./yaml/tomcat.yaml
```

##### Postgresql

```bash
kubectl delete -f ./yaml/postgresql.yaml
```

```bash
kubectl apply -f ./yaml/postgresql.yaml
```

```bash
kubectl exec -it [POSTGRESQL POD NAME] /bin/bash
```

```bash
psql -U postgres -f /var/lib/postgresql/backup.pgsql
```

```bash
psql -U postgres
```

```bash
DROP DATABASE user_database;
```



-------

### 3-Tier(Web/WAS) 이중화 - DNS 별도 등록 필요

#### 1. MetalLB 배포

``` bash
kubectl create ns metallb-system
```

```bash
helm upgrade --install -n metallb-system metallb oci://registry-1.docker.io/bitnamicharts/metallb
```

```bash
vi ./yaml/metallb_config.yaml
```

##### metallb_config.yaml

```
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool
  namespace: metallb-system
spec:
  addresses:
    - [K8S MASTER NODE VIRTUAL IP]/32
  autoAssign: true

# -------------------- 생략 --------------------
```

```bash
kubectl apply -f ./yaml/metallb_config.yaml
```



#### 2. Nginx Ingress Controller 배포

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

```bash
helm repo update
```

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
```



#### 3. Nginx 재배포

```bash
vi ./yaml/nginx.yaml
```

##### nginx.yaml

```
# -------------------- 생략 --------------------

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2

# -------------------- 생략 --------------------

kind: Service
apiVersion: v1
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
  	port: 80
    targetPort: 80
```



#### 4. Tomcat 재배포

```bash
vi ./yaml/tomcat.yaml
```

##### tomcat.yaml

```
# -------------------- 생략 --------------------

apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat
spec:
  replicas: 2

# -------------------- 생략 --------------------

kind: Service
apiVersion: v1
metadata:
  name: tomcat-service
spec:
  selector:
    app: tomcat
  ports:
  - protocol: TCP
  	port: 80
    targetPort: 80
```



#### 5. Ingress 배포 (DNS 수정 필요)

```bash
vi ./yaml/ingress.yaml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: 3-tier-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: <NGINX HOST DNS>
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
  - host: <TOMCAT HOST DNS>
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tomcat-service
            port:
              number: 8080
```

```bash
kubectl apply -f ./yaml/ingress.yaml
```



-------

### 3-Tier(Web/WAS) 인증서 적용

#### 1. Cert Manager 배포

```bash
kubectl apply -f ./yaml/cert-manager.yaml
```



#### 2. RootCA 인증서로 Secret 생성

```bash
kubectl create secret tls nginx-ingress-root-certificate \
  --cert=rootca.crt \
  --key=rootca.key
```

```bash
kubectl create secret tls nginx-ingress-root-certificate \
  --cert=rootca.crt \
  --key=rootca.key \
  --namespace=cert-manager
```



#### 3. ClusterIssuer 수정 후 생성

```bash
vi ./yaml/cluster_issuer.yaml
```

```bash
kubectl apply -f ./yaml/cluster_issuer.yaml
```



#### 4. Certificate 수정 후 생성

```bash
vi ./yaml/certificate.yaml
```

```bash
kubectl apply -f ./yaml/certificate.yaml
```



#### 4. Ingress 수정

```bash
vi ./yaml/ingress.yaml
```

##### ingress.yaml (기존 내용에 아래 내용 추가)

```
# -------------------- 생략 --------------------

	annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-com-tls
    
# -------------------- 생략 --------------------
```

```bash
kubectl apply -f ./yaml/ingress.yaml
```



---------

### 3-Tier(DB) 이중화 및 인증서 적용

#### 1. 기존 Postgresql 삭제

```bash
kubectl delete -f ./yaml/postgresql.yaml
```



#### 2. DB 이중화를 위한 Helm Repository 추가 및 Chart 다운로드

```bash
cd ./helm
```

```bash
helm repo add postgresql https://charts.bitnami.com/bitnami
```

```bash
helm fetch postgresql/postgresql-ha
```

```bash
tar -xvf postgresql-ha-14.2.16.tgz
```



#### 3. Values 파일 수정

```bash
vi ./postgresql-ha/values.yaml
```

##### values.yaml

```
# -------------------- 생략 --------------------

global:
	defaultStorageClass: "local-storage"
  storageClass: "local-storage"
  postgresql:
    username: "gweowe"
    password: "gweowe123"
    database: "user_data"
    repmgrUsername: "gweowe"
    repmgrPassword: "gweowe123"
    repmgrDatabase: "user_data"
  
# -------------------- 생략 --------------------

postgresql:
	replicaCount: 2
	
# -------------------- 생략 --------------------

postgresql:
	tls:
		enabled: true
    preferServerCiphers: true
    certificatesSecret: "nginx-ingress-certificate"
    certFilename: "tls.crt"
    certKeyFilename: "tls.key"

# -------------------- 생략 --------------------

pgpool:
	tls:
		enabled: true
    autoGenerated: false
    preferServerCiphers: true
    certificatesSecret: "nginx-ingress-certificate"
    certFilename: "tls.crt"
    certKeyFilename: tls.key
    certCAFilename: "ca.crt"

# -------------------- 생략 --------------------

volumePermissions:
  enabled: true
  
# -------------------- 생략 --------------------

persistence:
  enabled: false
  
# -------------------- 생략 --------------------
```



#### 4. Postgresql 배포

```bash
helm install postgresql ./postgresql-ha -f ./postgresql-ha/values.yaml
```



#### 5. Postgresql 데이터 재생성

```bash
kubectl exec -it postgresql-postgresql-ha-postgresql-0 /bin/bash
```

```bash
psql -d user_data -U gweowe
```

```bash
CREATE TABLE user_info (
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    ETC VARCHAR(255) NULL
);
```

```bash
INSERT INTO user_info (name, email, etc)
VALUES ('test_user', 'test_user@test.com', 'test1');
```

```bash
exit
```

```bash
exit
```



#### 5. Postgresql 로드벨런싱을 위한 Nginx Configmap 생성

```bash
kubectl apply -f ./yaml/nginx_ingress_configmap.yaml
```



#### 6. Nginx Ingress Controller 수정

```bash
kubectl edit service ingress-nginx-controller -n ingress-nginx
```

```
# -------------------- 생략 --------------------

spec:
	ports:
	- name: postgresql
   	port: 5432
    targetPort: 5432
    protocol: TCP
    
# -------------------- 생략 --------------------
```

```bash
kubectl edit deployment ingress-nginx-controller -n ingress-nginx
```

```
# -------------------- 생략 --------------------

		spec:
      containers:
      - args:
        - /nginx-ingress-controller
        - --tcp-services-configmap=ingress-nginx/tcp-services

# -------------------- 생략 --------------------
```

---
