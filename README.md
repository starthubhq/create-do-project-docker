```docker build -t create-do-project-docker .```

```docker build -t starthub-do-project .     
docker run --rm \
  -e do_access_token="<access_token>" \
  -e do_project_name="<project-name>" \
  starthub-do-project
```