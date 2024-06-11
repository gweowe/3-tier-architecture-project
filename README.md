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
  - CNI: Calico
  - Pod CIDR: 10.0.0.0/16
  - Container Runtime: Containerd



#### Web

(미정)



#### WAS

(미정)



#### DB

(미정)





## 구축 과정

