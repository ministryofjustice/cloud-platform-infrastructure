exports.onExecutePostLogin = async (event, api) => {
  const fetch = require("node-fetch");
  const modsecClientId =
    event.client.client_id === event.secrets.OPENSEARCH_APP_CLIENT_ID &&
    event.connection.name === "github";
  const appClientId =
    event.client.client_id ===
      event.secrets.OPENSEARCH_APP_CLIENT_ID_APP_LOGS &&
    event.connection.name === "github";
  const auth0TenantDomain = event.secrets.AUTH0_TENANT_DOMAIN;
  const MGMT_ID = event.secrets.MGMT_ID;
  const MGMT_SECRET = event.secrets.MGMT_SECRET;

  // Apply to 'github' connections only
  if (modsecClientId || appClientId) {
    const url = `https://${auth0TenantDomain}/oauth/token`;

    var data = {
      grant_type: "client_credentials",
      client_id: MGMT_ID,
      client_secret: MGMT_SECRET,
      audience: `https://${auth0TenantDomain}/v2/`,
    };

    try {
      var mgmt_response = await fetch(url, {
        method: "POST",
        body: JSON.stringify(data),
      });
    } catch (e) {
      console.log(e);
      api.access.deny("Could not post data to management api");
    }

    const headers = {
      Authorization: "Bearer " + mgmt_response.data.access_token,
      "content-type": "application/json",
    };
    const idp_url = `https://${auth0TenantDomain}/api/v2/users/${event.user.user_id}`;

    try {
      var idp_response = await fetch(idp_url, { headers });
    } catch (e) {
      console.log(e);
      api.access.deny("Could not get idp details");
    }

    // Get user's Github profile info (an Auth0 user can have multiple
    // connected accounts - Google, Facebook etc)
    //
    // Github user profile will also contain a Github API access token
    // which we can use to look up teams etc.
    const github_identity = idp_response.data.identities.find(
      (id) => id.connection === "github",
    );

    // Get list of user"s Github teams
    const teams_req = {
      url: "https://api.github.com/user/teams?per_page=100",
      headers: {
        Authorization: "token " + github_identity.accessToken,
        "User-Agent": "request",
      },
    };

    const response = await fetch(teams_req.url, { headers: teams_req.headers });
    const body = await response.json();

    if (response.status !== 200) {
      return api.access.deny("Error retrieving teams from github: " + body);
    }

    const git_teams = body.map((team) => {
      if (team.organization.login === "ministryofjustice") {
        return team.slug;
      }
    });

    if (git_teams.indexOf("webops") >= 0) {
      const allOrgMembersIdx = git_teams.indexOf("all-org-members");

      git_teams.splice(allOrgMembersIdx, 1);
    }

    api.user.GithubTeam = git_teams;

    api.samlResponse.setAttribute(
      "http://schemas.xmlsoap.org/claims/Group",
      "GithubTeam",
    );
  }
  return;
};
