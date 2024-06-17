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

(미정)



#### WAS

(미정)



#### DB

(미정)





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

### 3 Tier 구축

