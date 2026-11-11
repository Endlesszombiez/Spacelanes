package antigravity

import (
	"context"
	"io"
	"net/http"
	"net/url"
	"strings"
	"testing"
)

type environmentTestTransport func(*http.Request) (*http.Response, error)

func (f environmentTestTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func TestOAuthClientCredentialsFromEnvironment(t *testing.T) {
	t.Setenv("ANTIGRAVITY_OAUTH_CLIENT_ID", "")
	t.Setenv("ANTIGRAVITY_OAUTH_CLIENT_SECRET", "")
	if ClientID() != "" || ClientSecret() != "" {
		t.Fatal("missing environment must not fall back to embedded credentials")
	}
	t.Setenv("ANTIGRAVITY_OAUTH_CLIENT_ID", " fixture-client ")
	t.Setenv("ANTIGRAVITY_OAUTH_CLIENT_SECRET", " fixture-secret ")
	auth := NewAntigravityAuth(nil, &http.Client{Transport: environmentTestTransport(func(req *http.Request) (*http.Response, error) {
		if err := req.ParseForm(); err != nil {
			t.Fatal(err)
		}
		if req.Form.Get("client_id") != "fixture-client" || req.Form.Get("client_secret") != "fixture-secret" {
			t.Fatal("token exchange must use the configured OAuth client")
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(`{"access_token":"fixture-token"}`)),
			Header:     make(http.Header),
		}, nil
	})})
	u, err := url.Parse(auth.BuildAuthURL("fixture-state", "http://localhost/callback"))
	if err != nil {
		t.Fatal(err)
	}
	if u.Query().Get("client_id") != "fixture-client" || u.Query().Get("state") != "fixture-state" {
		t.Fatal("authorization URL must preserve state and use the configured client")
	}
	token, err := auth.ExchangeCodeForTokens(context.Background(), "fixture-code", "http://localhost/callback")
	if err != nil || token.AccessToken != "fixture-token" {
		t.Fatalf("token exchange failed: %v", err)
	}
}
