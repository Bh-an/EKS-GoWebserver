package config

import (
	"encoding/json"
	"log"
	"os"
)

// Config file structure
type Config struct {
	Server struct {
		Port int `json:"port"`
	} `json:"server"`
}

// Loads server config from file
func LoadConfig() (*Config, error) {
	file, err := os.Open("config.json")
	if err != nil {
		return nil, err
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	config := &Config{}
	err = decoder.Decode(config)
	if err != nil {
		return nil, err
	}

	log.Printf("Config loaded sucessfully")
	return config, nil
}
