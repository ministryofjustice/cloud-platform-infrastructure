// Allows users to log in to AWS with their Github identity
// Taken from: https://auth0.com/docs/integrations/aws/sso

function (user, context, callback) {
  var request = require('request');

  // Apply to 'github' connections only
  if(context.connection === 'github'){
    var github_identity = _.find(user.identities, { connection: 'github' });

    // Get user's Github team list
    var teams_req = {
      url: 'https://api.github.com/user/teams',
      headers: {
        'Authorization': 'token ' + github_identity.access_token,
        'User-Agent': 'request'
      }
    };

    request(teams_req, function (err, resp, body) {
      if (resp.statusCode !== 200) {
        return callback(new Error('Error retrieving teams from github: ' + body || err));
      }

      // IAM resource constants
      // `idp_arn` - reference to the SAML provider that has a trust relationship with AWS
      var idp_arn = "arn:aws:iam::926803513772:saml-provider/shared-auth0";
      var role_base_arn = "arn:aws:iam::926803513772:role/";

      // Add list of IAM roles that the user can assume, one role per Github team
      // SAML spec requires that the IDP identifier is included with each role
      // identifier, separated with a comma
      user.awsRole = JSON.parse(body).map(function (team) {
        return role_base_arn + "test-github-" + team.slug + "," + idp_arn;
      });

      // Name for the user's login session, typically their username
      // The AWS console will display the logged-in account as `role_name/session_name`,
      // e.g. `github_webops/kerin`
      user.awsRoleSession = user.nickname;
    
      // Map the user's AWS roles and session name to the equivalent SAML attributes
      context.samlConfiguration.mappings = {
        'https://aws.amazon.com/SAML/Attributes/Role': 'awsRole',
        'https://aws.amazon.com/SAML/Attributes/RoleSessionName': 'awsRoleSession'
      };

      return callback(null, user, context);
    });

  } else {
    return callback(null, user, context);
  }
}
