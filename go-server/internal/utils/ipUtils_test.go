package utils

import (
	"net/http"
	"strings"
	"testing"
	"time"
)

func TestGetLocation(t *testing.T) {
	tests := []struct {
		name        string
		headers     map[string]string
		expected    *time.Location
		expectedErr bool
	}{
		{
			name:        "Valid Timezone",
			headers:     map[string]string{"X-Timezone": "America/New_York"},
			expected:    mustLoadLocation("America/New_York"),
			expectedErr: false,
		},
		{
			name:        "Invalid Timezone",
			headers:     map[string]string{"X-Timezone": "Invalid/Timezone"},
			expected:    time.UTC,
			expectedErr: false,
		},
		{
			name:        "No Timezone",
			headers:     map[string]string{},
			expected:    time.UTC,
			expectedErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &http.Request{Header: http.Header{}}
			for k, v := range tt.headers {
				req.Header.Set(k, v)
			}

			actual := GetLocation(req)
			if actual.String() != tt.expected.String() {
				t.Errorf("GetLocation() = %v, expected %v", actual, tt.expected)
			}
		})
	}
}

func TestGetIP(t *testing.T) {
	tests := []struct {
		name       string
		headers    map[string]string
		remoteAddr string
		expected   string
	}{
		{
			name:       "X-Forwarded-For",
			headers:    map[string]string{"X-Forwarded-For": "10.0.0.1"},
			remoteAddr: "192.168.1.1",
			expected:   "10.0.0.1",
		},
		{
			name:       "RemoteAddr",
			headers:    map[string]string{},
			remoteAddr: "192.168.1.1",
			expected:   "192.168.1.1",
		},
		{
			name:       "Multiple X-Forwarded-For",
			headers:    map[string]string{"X-Forwarded-For": "10.0.0.1, 10.0.0.2, 10.0.0.3"},
			remoteAddr: "192.168.1.1",
			expected:   "10.0.0.1",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &http.Request{Header: http.Header{}, RemoteAddr: tt.remoteAddr}
			for k, v := range tt.headers {
				req.Header.Set(k, v)
			}
			actual := GetIP(req)
			if strings.Contains(tt.headers["X-Forwarded-For"], ",") {
				if !strings.HasPrefix(actual, tt.expected) {
					t.Errorf("GetIP() = %v, expected %v", actual, tt.expected)
				}
			} else if actual != tt.expected {
				t.Errorf("GetIP() = %v, expected %v", actual, tt.expected)
			}
		})
	}
}

// Helper function to safely load a time.Location
func mustLoadLocation(name string) *time.Location {
	loc, err := time.LoadLocation(name)
	if err != nil {
		panic(err)
	}
	return loc
}
