package utils

import (
	"time"
)

func GetCurrentTime(location *time.Location) string {

	timeNow := time.Now().In(location)

	return timeNow.Format("2006-January-02 15:04:05 MST")

}
