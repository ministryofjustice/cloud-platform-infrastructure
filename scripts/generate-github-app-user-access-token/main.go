package main

import (
	"fmt"
	"github.com/google/go-github/v32/github"
	"golang.org/x/oauth2"
	"net/http"
	"os"
)

var (
	clientID     = "XXXXXXXXXXXXXXXXXXXX"
	clientSecret = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	redirectURL  = "http://localhost:3000/github/callback"
)

var githubOAuthConfig = oauth2.Config{
	ClientID:     clientID,
	ClientSecret: clientSecret,
	Scopes:       []string{"user", "repo"}, // Adjust scopes as needed
	Endpoint: oauth2.Endpoint{
		AuthURL:  "https://github.com/login/oauth/authorize",
		TokenURL: "https://github.com/login/oauth/access_token",
	},
}

func handleGitHubLogin(w http.ResponseWriter, r *http.Request) {
	url := githubOAuthConfig.AuthCodeURL("state")
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

func handleGitHubCallback(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "Missing code parameter", http.StatusBadRequest)
		return
	}

	token, err := githubOAuthConfig.Exchange(r.Context(), code)
	if err != nil {
		http.Error(w, "Failed to exchange code for token", http.StatusInternalServerError)
		return
	}

	// Use the token to create a GitHub client
	client := github.NewClient(githubOAuthConfig.Client(r.Context(), token))

	// Example: Get the authenticated user
	user, _, err := client.Users.Get(r.Context(), "")
	if err != nil {
		http.Error(w, "Failed to get user information", http.StatusInternalServerError)
		return
	}

	// Display user information or redirect to another page
	fmt.Fprintf(w, "Logged in as: %s\n", user.GetLogin())
	fmt.Fprintf(w, "Access Token: %s\n", token.AccessToken)
}

func main() {
	http.HandleFunc("/", handleGitHubLogin)

	http.HandleFunc("/github/callback", handleGitHubCallback)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}
	fmt.Printf("Starting server on http://localhost:%s\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Printf("Server error: %s\n", err)
	}
}
