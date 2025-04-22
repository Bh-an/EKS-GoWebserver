// Contains request/response handlers
package handlers

import (
	"encoding/json"
	"go-server/internal/models"
	"go-server/internal/utils"
	"log"
	"net/http"
)

// Handles '/' request/response
func DefaultHandler(w http.ResponseWriter, r *http.Request) {

	log.Printf("Request received at '/'")

	ip := utils.GetIP(r)
	timestamp := utils.GetCurrentTime(utils.GetLocation(r))

	response := models.TimeResponse{

		Timestamp: timestamp,
		IP:        ip,
	}

	log.Printf("Sending response: %v", response)

	w.Header().Set("Content-Type", "application/json")
	encoder := json.NewEncoder(w)
	err := encoder.Encode(response)

	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		log.Printf("Error encoding JSON: %v", err)
		return
	}

}
