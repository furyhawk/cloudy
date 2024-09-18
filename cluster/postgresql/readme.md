# postgresql

```bash
kubectl create ns postgresql-svc
kubectl config set-context --current --namespace=postgresql-svc
kubectl apply -f ps-configmap.yaml
kubectl apply -f ps-storage.yaml
kubectl get pvc
NAME                STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
postgres-pv-claim   Bound    postgres-pv-volume   2Gi        RWX            manual         <unset>                 6s

k apply -f ps-deployment.yaml
k apply -f ps-service.yaml

k get all
NAME                            READY   STATUS    RESTARTS   AGE
pod/postgres-84bd99bf45-sf6xq   1/1     Running   0          78s

NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/postgres   NodePort   10.43.158.173   <none>        5432:30795/TCP   12s

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres   1/1     1            1           78s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/postgres-84bd99bf45   1         1         1       78s

kubectl exec -it [pod-name] --  psql -h localhost -U admin --password -p [port] postgresdb

kubectl exec -it postgres-84bd99bf45-sf6xq --  psql -h localhost -U admin --password -p 5432 postgresdb

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgresql bitnami/postgresql --create-namespace -n 'postgresql-svc' --set persistence.existingClaim=postgresql-pv-claim --set volumePermissions.enabled=true

kubectl delete -f ps-deployment.yaml
kubectl delete -f ps-service.yaml
kubectl delete -f ps-configmap.yaml
kubectl delete -f ps-storage.yaml
