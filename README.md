IMAGE=ghcr.io/starthubhq/create-do-droplet-docker:0.0.5
docker build -t $IMAGE
docker push $IMAGE

```docker build -t create-do-project .
echo '{"state":{}, "params":{"do_project_name":"starthub-demo", "do_access_token": "<access_token>"}}' | docker run -i --rm create-do-project
```