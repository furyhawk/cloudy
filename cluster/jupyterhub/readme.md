# Installing JupyterHub
JupyterHub is a multi-user Hub that spawns, manages, and proxies multiple instances of the single-user Jupyter notebook server.

## Initialize a Helm chart configuration file
Helm charts’ contain templates that can be rendered to the Kubernetes resources to be installed. A user of a Helm chart can override the chart’s default values to influence how the templates render.

In this step we will initialize a chart configuration file for you to adjust your installation of JupyterHub. We will name and refer to it as config.yaml going onwards.

```bash
# This file can update the JupyterHub Helm chart's default configuration values.
#
# For reference see the configuration reference and default values, but make
# sure to refer to the Helm chart version of interest to you!
#
# Introduction to YAML:     https://www.youtube.com/watch?v=cdLNKUoMc6c
# Chart config reference:   https://zero-to-jupyterhub.readthedocs.io/en/stable/resources/reference.html
# Chart default values:     https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/HEAD/jupyterhub/values.yaml
# Available chart versions: https://hub.jupyter.org/helm-chart/
#
```

## Install JupyterHub
This is a simple jupyterhub deployment using helm.
```bash
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```
Now install the chart configured by your `config.yaml` by running this command from the directory that contains your `config.yaml`:
```bash
helm upgrade --cleanup-on-fail \
  --install <helm-release-name> jupyterhub/jupyterhub \
  --namespace <k8s-namespace> \
  --create-namespace \
  --version=<chart-version> \
  --values config.yaml
```
where:

- <helm-release-name> refers to a Helm release name, an identifier used to differentiate chart installations. You need it when you are changing or deleting the configuration of this chart installation. If your Kubernetes cluster will contain multiple JupyterHubs make sure to differentiate them. You can list your Helm releases with helm list.

- <k8s-namespace> refers to a Kubernetes namespace, an identifier used to group Kubernetes resources, in this case all Kubernetes resources associated with the JupyterHub chart. You’ll need the namespace identifier for performing any commands with kubectl.

- This step may take a moment, during which time there will be no output to your terminal. JupyterHub is being installed in the background.

- If you get a release named <helm-release-name> already exists error, then you should delete the release by running helm delete <helm-release-name>. Then reinstall by repeating this step. If it persists, also do kubectl delete namespace <k8s-namespace> and try again.

- In general, if something goes wrong with the install step, delete the Helm release by running helm delete <helm-release-name> before re-running the install command.

- If you’re pulling from a large Docker image you may get a Error: timed out waiting for the condition error, add a --timeout=<number-of-minutes>m parameter to the helm command.

- The --version parameter corresponds to the version of the Helm chart, not the version of JupyterHub. Each version of the JupyterHub Helm chart is paired with a specific version of JupyterHub. E.g., 0.11.1 of the Helm chart runs JupyterHub 1.3.0. For a list of which JupyterHub version is installed in each version of the JupyterHub Helm Chart, see the Helm Chart repository.

```bash
helm upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --create-namespace \
  --values config.yaml
```

Find the IP we can use to access the JupyterHub. Run the following command until the EXTERNAL-IP of the proxy-public service is available like in the example output.
```bash
kubectl --namespace <k8s-namespace> get service proxy-public
```
where <k8s-namespace> is the namespace you installed JupyterHub into. The output will look like this:
```bash
NAME           TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
proxy-public   LoadBalancer   10.51.248.230   104.196.41.97   80:31916/TCP   1m
```
To use JupyterHub, enter the external IP for the proxy-public service in to a browser. JupyterHub is running with a default dummy authenticator so entering any username and password combination will let you enter the hub.

Congratulations! Now that you have basic JupyterHub running, you can extend it and optimize it in many ways to meet your needs.