```docker build -t create-do-project .
echo '{"state":{}, "params":{"do_project_name":"starthub-demo", "do_access_token": "<access_token>"}}' | docker run -i --rm create-do-project
```