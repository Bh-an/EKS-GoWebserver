package utils

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

// Function for getting location from 'X-Timezone' attribute of HTTP header
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

// Function for getting client IP from the 'X-Forwaded-For' attribute of HTTP header
func GetIP(r *http.Request) string {
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		return forwarded
	}
	return r.RemoteAddr
}
