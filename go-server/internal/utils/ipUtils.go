package utils

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func GetLocation(r *http.Request) *time.Location {

	timezoneName := r.Header.Get("X-Timezone")
	var location *time.Location
	var err error

	fmt.Printf("Timezone name: %v", timezoneName)

	if timezoneName != "" {
		location, err = time.LoadLocation(timezoneName)
		if err != nil {
			log.Printf("Invalid timezone: %s", timezoneName)
			location = time.UTC
		}
	} else {
		location = time.UTC
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
