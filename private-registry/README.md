# Setup a private docker registry

## connect your local Docker to with the registry

```shell script
docker login -u <YOUR_LOGIN> -u <YOUR_PASSWORD> <REGISTRY_HOST>
```

## Create a secret with the registry information.

Encode your `~/.docker/config.json` in base64:
```shell script
cat ~/.docker/config.json | base64
```
Create a file my-secret.yml with these informations
```yaml
apiVersion: v1
kind: Secret
metadata:
 name: registrypullsecret
data:
 .dockerconfigjson: <base-64-encoded-json-here>
type: kubernetes.io/dockerconfigjson
```