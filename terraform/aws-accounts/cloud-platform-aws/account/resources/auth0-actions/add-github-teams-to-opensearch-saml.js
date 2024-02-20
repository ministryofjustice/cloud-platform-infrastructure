exports.onExecutePostLogin = async (event, api) => {
  const fetch = require("node-fetch")
  const modsecClientId = event.client.client_id === event.secrets.OPENSEARCH_APP_CLIENT_ID && event.connection.name === "github";
  const appClientId = event.client.client_id === event.secrets.OPENSEARCH_APP_CLIENT_ID_APP_LOGS && event.connection.name === "github";

  // Apply to 'github' connections only
  if (modsecClientId || appClientId) {
    // Get user's Github profile info (an Auth0 user can have multiple
    // connected accounts - Google, Facebook etc)
    //
    // Github user profile will also contain a Github API access token
    // which we can use to look up teams etc.
    const github_identity = user.identities.find(id => id.connection === "github");

    // Get list of user"s Github teams
    const teams_req = {
      url: 'https://api.github.com/user/orgs',
      headers: {
        'Authorization': 'token ' + github_identity.accessToken
      }
    };

    const response = await fetch(teams_req.url, { headers: teams_req.headers });
    const body = await response.json();

    if (response.status !== 200) {
      return api.access.deny('Error retrieving teams from github: ' + body)
    }

    const git_teams = body.map((team) => {
      if (team.organization.login === "ministryofjustice") {
        return team.slug;
      }
    });

    event.user.GithubTeam = git_teams

    api.samlResponse.setAttribute("http://schemas.xmlsoap.org/claims/Group", "GithubTeam")
  }
  return
}

