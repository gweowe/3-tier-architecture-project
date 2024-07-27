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



----------------

### 3-Tier 이중화
