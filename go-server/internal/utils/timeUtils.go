package utils

import (
	"time"
)

// Function for getting current lime based on international/tz timezones (defaults to UTC)
func GetCurrentTime(location *time.Location) string {

	timeNow := time.Now().In(location)

	return timeNow.Format("2006-January-02 15:04:05 MST")

}
