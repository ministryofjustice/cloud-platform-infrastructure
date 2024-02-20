exports.onExecutePostLogin = async (event, api) => {
  const fetch = require("node-fetch")

  const github_org_allow_list = ['ministryofjustice'];
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
      url: 'https://api.github.com/user/orgs',
      headers: {
        'Authorization': 'Bearer ' + github_identity.accessToken
      }
    };

    const response = await fetch(orgs_req.url, { headers: orgs_req.headers });

    const body = await response.json();

    if (response.status !== 200) {
      return api.access.deny('Error retrieving orgs from github: ' + body)
    }

    // Construct list of Github org names
    const user_orgs = body.map((org) => org.login);

    const authorized = github_org_allow_list.some((org) => user_orgs.indexOf(org) !== -1);

    if (!authorized) {
      return api.access.deny('Access was denied.')
    }
  }
  return
}
