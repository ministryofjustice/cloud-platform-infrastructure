exports.onExecutePostLogin = async (event, api) => {
  const fetch = require("node-fetch")
  // Apply to 'github' connections only
  if (event.connection.name === 'github') {
    // Get user's Github profile info (an Auth0 user can have multiple
    // connected accounts - Google, Facebook etc)
    //
    // Github user profile will also contain a Github API access token
    // which we can use to look up teams etc.
    const github_identity = event.user.identities.find(id => id.connection === 'github');
    // Get list of Github orgs for the user
    const orgs_req = {
      url: 'https://api.github.com/user/teams',
      headers: {
        'Authorization': 'Bearer ' + github_identity.accessToken
      }
    };

    const response = await fetch(orgs_req.url, { headers: orgs_req.headers });
    const body = await response.json();

    if (response.status !== 200) {
      return api.access.deny('Error retrieving teams from github: ' + body)
    }

    // Construct list of user's Github teams
    // The team slug is used, to normalise whitespace, capitalisation etc.
    const git_teams = body.map((team) => {
      if (team.organization.login === "ministryofjustice") {
        return "github:" + team.slug;
      }
    });

    // Add team list to the user's JWT as a custom claim
    //
    // Custom OIDC claims should be prefixed with a unique value
    // to prevent clashes with claims from other sources.
    // Common practice is to use a URL
    api.idToken.setCustomClaim(event.secrets.K8S_OIDC_GROUP_CLAIM_DOMAIN, git_teams);
  }
  return
}

