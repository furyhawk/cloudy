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

helm install postgresql oci://registry-1.docker.io/bitnamicharts/postgresql
Pulled: registry-1.docker.io/bitnamicharts/postgresql:15.5.32
Digest: sha256:77eac6044be9413a5463045f8ee20d8574be7e94e81792ddecb4972534f4e45f
NAME: postgresql
LAST DEPLOYED: Wed Sep 18 19:15:57 2024
NAMESPACE: postgresql-svc
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 15.5.32
APP VERSION: 16.4.0

** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    postgresql.postgresql-svc.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgresql-svc postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

To connect to your database run the following command:

    kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace postgresql-svc --image docker.io/bitnami/postgresql:16.4.0-debian-12-r9 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgresql -U postgres -d postgres -p 5432

    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace postgresql-svc svc/postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432

WARNING: The configured password will be ignored on new installation in case when previous PostgreSQL release was deleted through the helm command. In that case, old PVC will have an old password, and setting it through helm won't take effect. Deleting persistent volumes (PVs) will solve the issue.

WARNING: There are "resources" sections in the chart not set. Using "resourcesPreset" is not recommended for production. For production installations, please set the following values according to your workload needs:
  - primary.resources
  - readReplicas.resources
+info https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

```