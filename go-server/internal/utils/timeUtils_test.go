package utils

import (
	"testing"
	"time"
)

// Testing function for getting current time in a timezone
func TestGetCurrentTime(t *testing.T) {
	tests := []struct {
		name     string
		location *time.Location
	}{
		{
			name:     "UTC",
			location: time.UTC,
		},
		{
			name:     "Local",
			location: time.Local,
		},
		{
			name:     "New York",
			location: loadLocation("America/New_York"),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			currentTime := GetCurrentTime(tt.location)
			parsedTime, err := time.ParseInLocation("2006-January-02 15:04:05 MST", currentTime, tt.location)
			if err != nil {
				t.Errorf("GetCurrentTime() returned an unparsable time string: %v", err)
			}

			now := time.Now().In(tt.location)
			if parsedTime.Year() != now.Year() || parsedTime.Month() != now.Month() || parsedTime.Day() != now.Day() {
				t.Errorf("GetCurrentTime() returned a time string that differs significantly from the current time. Expected at the same day, got %v", parsedTime)
			}
		})
	}
}

// Testing function for loading time.location object
func loadLocation(name string) *time.Location {
	loc, err := time.LoadLocation(name)
	if err != nil {
		panic(err)
	}
	return loc
}
