package utils

import (
	"log"
	"net/http"
	"time"
)

func GetLocation(r *http.Request) *time.Location {

	timezoneName := r.Header.Get("X-Timezone")
	var location *time.Location
	var err error

	if timezoneName != "" {
		location, err = time.LoadLocation(timezoneName)
		if err != nil {
			log.Printf("Invalid timezone: %s", timezoneName)
			location = time.Local // fallback to server's location for invalid timezone
		}
	} else {
		location = time.Local // If no timezone given, use the server's timezone.
	}

	return location
}

func GetIP(r *http.Request) string {
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		return forwarded
	}
	return r.RemoteAddr
}
