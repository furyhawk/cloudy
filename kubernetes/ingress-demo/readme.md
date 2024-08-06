# ingress demo

```bash
k create -f nginx-deploy-main.yaml -f nginx-deploy-blue.yaml -f nginx-deploy-green.yaml
k get all
```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/nginx-deploy-blue-5cf4dbd98b-kzxp7    1/1     Running   0          23s
pod/nginx-deploy-green-64879cd747-7lrkh   1/1     Running   0          23s
pod/nginx-deploy-main-59657668d9-4qgdh    1/1     Running   0          23s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   17h

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deploy-blue    1/1     1            1           23s
deployment.apps/nginx-deploy-green   1/1     1            1           23s
deployment.apps/nginx-deploy-main    1/1     1            1           23s

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deploy-blue-5cf4dbd98b    1         1         1       23s
replicaset.apps/nginx-deploy-green-64879cd747   1         1         1       23s
replicaset.apps/nginx-deploy-main-59657668d9    1         1         1       23s

```bash
k expose deploy nginx-deploy-green --port 80
k expose deploy nginx-deploy-main --port 80
```

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes           ClusterIP   10.43.0.1      <none>        443/TCP   17h
nginx-deploy-green   ClusterIP   10.43.47.11    <none>        80/TCP    62s
nginx-deploy-main    ClusterIP   10.43.148.11   <none>        80/TCP    46s

hosts
```
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
# Added by Docker Desktop
# To allow the same kube context to work on the host and the container:
127.0.0.1 kubernetes.docker.internal
# End of section

127.0.0.1       www.local.test
127.0.0.1       api.local.test

192.168.50.190  rancher.local
192.168.50.191  traefik.local nginx.traefik.local
```

```bash
k get ingressroutes
k create -f traefik/simple-ingress-routes/1-ingressroute.yaml
# http://traefik.local/
k delete -f traefik/simple-ingress-routes/1-ingressroute.yaml
k apply -f traefik/simple-ingress-routes/2-ingressroute.yaml
# http://traefik.local/
# http://nginx.traefik.local/
k delete -f traefik/simple-ingress-routes/2-ingressroute.yaml
k apply -f traefik/simple-ingress-routes/3-ingressroute.yaml
# http://green.traefik.local/
k delete -f traefik/simple-ingress-routes/3-ingressroute.yaml
```