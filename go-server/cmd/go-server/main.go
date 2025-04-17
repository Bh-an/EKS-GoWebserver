package main

import (
	"fmt"
	"go-server/internal/config"
	"go-server/internal/handlers"
	"log"
	"net/http"
)

func main() {
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Error loading config: %v", err)
	}

	http.HandleFunc("/", handlers.DefaultHandler)

	log.Printf("Server listening on :%d\n", cfg.Server.Port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", cfg.Server.Port), nil))
}
