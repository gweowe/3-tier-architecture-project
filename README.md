# 3tier-architecture-project

## 개요

3 Tier Architecture 구축이 프로젝트의 궁극적인 목적이며, 자체적으로 요구사항을 제시하여 고도화 진행 예정



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

#### 2회 차 (2024/07/04 ~ 2024/07/31)

1. Web/WAS/DB 이중화 구현
2. Web/WAS/DB SSL/TLS 구현

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
  - 데이터 공유를 위한 NFS 서버 1대 운용
  

#### Web

- Name: Nginx
- Version: 1.27.0

#### WAS

- Name: Tomcat
- Version: 10.1.24
- JDK: 21.0.3

- JDBC: PostgreSQL 42.7.3

#### DB

- Name: PostgreSQL
- Version: 16.3.1



## 구성도

(준비 중)
