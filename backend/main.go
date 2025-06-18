package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/imdawon/personalos/api"
	"github.com/imdawon/personalos/models"
	"github.com/imdawon/personalos/processor"
	"github.com/imdawon/personalos/storage"
	"github.com/imdawon/personalos/tracker"
)

const (
	dbPath             = "personal_os.db"
	trackingInterval   = 5 * time.Second
	processingInterval = 1 * time.Minute
	apiAddr            = "localhost:8085"
)

func main() {
	log.Println("Starting Personal OS Backend...")

	// 1. Initialize Storage
	store, err := storage.NewDBStore(dbPath)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	log.Println("Database initialized.")

	// 2. Initialize the Platform-Specific Tracker
	activityTracker, err := tracker.NewTracker()
	if err != nil {
		log.Fatalf("Failed to initialize tracker for this OS: %v", err)
	}
	log.Println("Activity tracker initialized.")

	// 3. Start the continuous logger (the "eye")
	go startLogger(activityTracker, store)

	// 4. Start the Processor
	proc := processor.NewProcessor(store, processingInterval)
	proc.Start()

	// 5. Start the API Server
	apiServer := api.NewServer(store)
	go apiServer.Start(apiAddr)

	// Wait for shutdown signal
	waitForShutdown(proc)
	log.Println("Personal OS Backend shut down gracefully.")
}

// startLogger is the core loop that gets activity and logs it.
func startLogger(t tracker.Tracker, s *storage.DBStore) {
	ticker := time.NewTicker(trackingInterval)
	defer ticker.Stop()

	log.Println("Logger started. Tracking activity...")

	var lastPowerStateLog time.Time
	var isCurrentlyPaused bool

	for range ticker.C {
		activity, err := t.GetActivity()
		if err != nil {
			// Check if this is a power state related error (tracking paused)
			if isPowerStateError(err) {
				if !isCurrentlyPaused {
					log.Printf("Not Paused: Tracking paused: %v", err)
					isCurrentlyPaused = true
				}
				continue
			}

			// Log other errors but continue tracking
			log.Printf("Error getting activity: %v", err)
			continue
		}

		// If we were previously paused, log that tracking has resumed
		if isCurrentlyPaused {
			log.Println("Tracking resumed - system is active")
			isCurrentlyPaused = false
		}

		if activity.AppName != "" {
			event := models.RawEvent{
				Timestamp:   time.Now(),
				AppName:     activity.AppName,
				WindowTitle: activity.WindowTitle,
			}
			if err := s.InsertRawEvent(event); err != nil {
				log.Printf("Error inserting raw event: %v", err)
			}
			log.Printf("Logged Raw Event: %s - %s", activity.AppName, activity.WindowTitle)
		}

		// Log power state information periodically (every 5 minutes)
		if time.Since(lastPowerStateLog) > 5*time.Minute {
			if powerState, err := t.GetPowerState(); err == nil {
				log.Printf("Power State - Sleeping: %v, Locked: %v, DisplaySleep: %v, Idle: %v",
					powerState.IsSleeping, powerState.IsLocked, powerState.IsDisplaySleep, powerState.IsIdle)
				lastPowerStateLog = time.Now()
			}
		}
	}
}

// isPowerStateError checks if the error is related to power state (tracking paused)
func isPowerStateError(err error) bool {
	return err != nil && (err.Error()[:15] == "tracking paused:")
}

// waitForShutdown handles graceful shutdown on interrupt signals.
func waitForShutdown(proc *processor.Processor) {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutdown signal received...")
	proc.Stop()
	// In a real app, you would also gracefully shut down the API server.
}
