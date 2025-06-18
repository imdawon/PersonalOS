package main

import (
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/imdawon/personalos/api"
	"github.com/imdawon/personalos/models"
	"github.com/imdawon/personalos/processor"
	"github.com/imdawon/personalos/storage"
	"github.com/imdawon/personalos/tracker"
)

const (
	dbPath                 = "personal_os.db"
	activeTrackingInterval = 5 * time.Second  // Fast polling when active
	pausedTrackingInterval = 30 * time.Second // Slow polling when locked/sleeping (battery conservation)
	processingInterval     = 1 * time.Minute
	apiAddr                = "localhost:8085"
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
	proc := processor.NewProcessor(store, processingInterval)
	go startLogger(activityTracker, store, proc)

	// 4. Start the Processor
	proc.Start()

	// 5. Start the API Server
	apiServer := api.NewServer(store)
	go apiServer.Start(apiAddr)

	// Wait for shutdown signal
	waitForShutdown(proc)
	log.Println("Personal OS Backend shut down gracefully.")
}

// startLogger is the core loop that gets activity and logs it with dynamic polling intervals.
func startLogger(t tracker.Tracker, s *storage.DBStore, proc *processor.Processor) {
	log.Println("Logger started. Tracking activity...")

	var lastPowerStateLog time.Time
	var isCurrentlyPaused bool
	var currentInterval = activeTrackingInterval

	// Use a channel-based approach for dynamic interval switching
	tickerChan := make(chan time.Time)
	var ticker *time.Ticker

	// Function to start/restart ticker with new interval
	startTicker := func(interval time.Duration) {
		if ticker != nil {
			ticker.Stop()
		}
		ticker = time.NewTicker(interval)
		go func() {
			for t := range ticker.C {
				tickerChan <- t
			}
		}()
	}

	// Start with active tracking interval
	startTicker(activeTrackingInterval)
	defer func() {
		if ticker != nil {
			ticker.Stop()
		}
	}()

	for range tickerChan {
		activity, err := t.GetActivity()
		if err != nil {
			// Check if this is a power state related error (tracking paused)
			if isPowerStateError(err) {
				if !isCurrentlyPaused {
					log.Printf("Tracking paused: %v", err)
					log.Printf("Switching to battery conservation mode (polling every %v)", pausedTrackingInterval)
					isCurrentlyPaused = true

					// Pause the processor - no need to process when no activity is being tracked
					proc.Pause()

					// Switch to slower polling interval to conserve battery
					if currentInterval != pausedTrackingInterval {
						currentInterval = pausedTrackingInterval
						startTicker(pausedTrackingInterval)
					}
				}
				continue
			}

			// Log other errors but continue tracking
			log.Printf("Error getting activity: %v", err)
			continue
		}

		// If we were previously paused, log that tracking has resumed and switch back to fast polling
		if isCurrentlyPaused {
			log.Println("Tracking resumed - system is active")
			log.Printf("Switching back to active tracking mode (polling every %v)", activeTrackingInterval)
			isCurrentlyPaused = false

			// Resume the processor - start processing accumulated events
			proc.Resume()

			// Switch back to faster polling interval
			if currentInterval != activeTrackingInterval {
				currentInterval = activeTrackingInterval
				startTicker(activeTrackingInterval)
			}
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
	if err == nil {
		return false
	}
	errMsg := err.Error()
	return strings.Contains(errMsg, "tracking paused:")
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
