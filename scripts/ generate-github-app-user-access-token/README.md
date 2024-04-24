# Generate Github App token

Cloud Platform concourse pipelines uses an user access token to read and write github secrets to ministryofjustice org repositories.
## Background
In order to generate the user access token, a [Github App - Cloud Platform Concourse][App settings] is created and installed. 
Note: This will need github owner permissions to install the app on all the repositories

This script uses [Web Application flow](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app#using-the-web-application-flow-to-generate-a-user-access-token) to generate the token

## How to run

### Inputs
This script needs `clientID` and `clientSecret` to authorise the request and exchange code
The `clientID` can be fetched from the Github App settings: 
The `clientSecret` is not stored anywhere purposefully so whenever a new user access token needs generating, create a new Client secret from [App settings][App settings] and use that as input.

### Setup the callback url in the App settings
The callback URL is where the user access token is returned after the authorization is successful. Update the callback url in the Github App settings -> "Callback URL" and save

### Running the script

To run the script execute 
```
go build main.go
chmod +x main
./main
```

Open the link http://localhost:3000 in the browser which should redirect to Authorize the app, Approve the permissions and that should redirect to the callback url "http://localhost:3000/github/callback" where the user and token details are printed as 

```
Logged in as: <Your Name>
Access Token: ghu_XXXXXX
```


[App settings]: https://github.com/organizations/ministryofjustice/settings/apps/cloud-platform-concourse