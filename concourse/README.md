`helm install --namespace development --name concourse -f concourse.yaml stable/concourse`

Values changed in the yaml (from the default obtained with `helm inspect values stable/concourse`):
 * URL (otherwise auth redirects to the internal 127.0.0.1:8080)
 * worker size (to check if mem/cpu caused slowness in web interf)
 * Postgresql passw (not sure if actually a concern)
 * githubAuthClientId/githubAuthClientSecret for auth

`helm upgrade -f concourse.yaml concourse stable/concourse` 
