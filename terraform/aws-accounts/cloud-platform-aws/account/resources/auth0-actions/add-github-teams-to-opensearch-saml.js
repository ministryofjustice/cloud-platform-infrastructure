exports.onExecutePostLogin = async (event, api) => {
  const modsecClientId =
    event.client.client_id === event.secrets.OPENSEARCH_APP_CLIENT_ID &&
    event.connection.name === "github";
  const appClientId =
    event.client.client_id ===
      event.secrets.OPENSEARCH_APP_CLIENT_ID_APP_LOGS &&
    event.connection.name === "github";

  if (modsecClientId || appClientId) {
    const git_teams = event.user.user_metadata["gh_teams"].map((t) =>
      t.replace("github:", ""),
    );

    if (git_teams.indexOf("webops") >= 0) {
      const allOrgMembersIdx = git_teams.indexOf("all-org-members");

      git_teams.splice(allOrgMembersIdx, 1);
    }

    api.user.GithubTeam = git_teams;

    api.samlResponse.setAttribute(
      "http://schemas.xmlsoap.org/claims/Group",
      git_teams,
    );
  }
};
