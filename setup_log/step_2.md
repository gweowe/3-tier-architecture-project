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

### 3-Tier(Web/WAS) 이중화

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



#### 5. Ingress 배포

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

---------

### 3-Tier(DB) 이중화

#### 1. DB 이중화를 위한 Helm Repository 추가 및 Chart 다운로드

```bash
cd ./helm
```

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

```bash
helm fetch bitnami/postgresql-ha
```

```bash
tar -xvf <Postgresql HA File>.tgz
```



#### 2. Value 파일 수정

```bash
vi ./postgresql-ha/values.yaml
```

##### Values.yaml

```bash
# -------------------- 생략 --------------------

global:
  defaultStorageClass: "local-storage"

# -------------------- 생략 --------------------

  postgresql:
    username: "gweowe"
    password: "gweowe123"
    database: "user_data"
    repmgrUsername: "gweowe"
    repmgrPassword: "gweowe123"
    repmgrDatabase: "user_data"
    
# -------------------- 생략 --------------------

  pgpool:
    adminUsername: "gweowe"
    adminPassword: "gweowe123"

# -------------------- 생략 --------------------

clusterDomain: "gweowe.com"

# -------------------- 생략 --------------------

postgresql:
	replicaCount: 2
	
# -------------------- 생략 --------------------
```



