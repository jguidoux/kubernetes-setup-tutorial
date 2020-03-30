# Setup a private docker registry
   
   ## connect your local Docker to the registry
   
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

## add the secret to your deploymentn manifests

add these lines to your deployement manifest at the same level as the `containers` keyword

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sa-logic
  namespace: sentiment-analysis
  labels:
    app: sa-logic
spec:
  selector:
     matchLabels:
       app: sa-logic
  replicas: 2
  minReadySeconds: 15
  strategy:
    type: RollingUpdate
    rollingUpdate: 
      maxUnavailable: 1
      maxSurge: 1 
  template:
    metadata:
      labels:
        app: sa-logic
    spec:
      containers:
        - image: rinormaloku/sentiment-analysis-logic
          imagePullPolicy: Always
          name: sa-logic
          ports:
            - containerPort: 5000
      # Add the secret here with his rame.
      imagePullSecrets:
              - name: registrypullsecret

```