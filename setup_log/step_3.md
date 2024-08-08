##  구축 과정

### Postgresql Auto Backup

#### 1. Cronjob 수정

```bash
vi ./yaml/cronjob.yaml
```



#### 2. Cronjob 실행

```bash
kubectl apply -f ./yaml/postgresql_backup_cronjob.yaml
```

