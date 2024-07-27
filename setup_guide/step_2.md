## 구축 과정

### NFS 서버 구축 및 PV 재설정 (NFS Server)

#### 1. nfs 패키지 설치

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

###### exports

```
[USER HOME PATH] [SHARE SERVER IP](rw,no_root_squash,sync)

# ex)
# /home/gweowe/ 1.1.*.*(rw,no_root_squash,sync)
```



#### 5. 설정 적용 및 확인

```bash
sudo exportfs -ra
```

```bash
sudo exportfs -v
```



#### 6. yaml 파일 수정



----------------

### Web/WAS/DB 이중화

#### 

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

