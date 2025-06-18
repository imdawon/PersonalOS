package processor

import (
	"log"
	"time"

	"github.com/imdawon/personalos/storage"
)

// Processor handles the aggregation of raw events into sessions.
type Processor struct {
	store    *storage.DBStore
	ticker   *time.Ticker
	quit     chan struct{}
	pause    chan struct{}
	resume   chan struct{}
	interval time.Duration
	isPaused bool
}

// NewProcessor creates a new Processor instance.
func NewProcessor(store *storage.DBStore, interval time.Duration) *Processor {
	return &Processor{
		store:    store,
		interval: interval,
		quit:     make(chan struct{}),
		pause:    make(chan struct{}),
		resume:   make(chan struct{}),
		isPaused: false,
	}
}

// Start begins the periodic processing of events.
func (p *Processor) Start() {
	log.Println("Processor started...")
	p.ticker = time.NewTicker(p.interval)

	go func() {
		for {
			select {
			case <-p.ticker.C:
				if !p.isPaused {
					log.Println("Processor running...")
					if err := p.store.ProcessRawEvents(); err != nil {
						log.Printf("Error processing raw events: %v", err)
					}
				}
			case <-p.pause:
				if !p.isPaused {
					log.Println("Processor paused - system inactive")
					p.isPaused = true
				}
			case <-p.resume:
				if p.isPaused {
					log.Println("Processor resumed - system active")
					p.isPaused = false
				}
			case <-p.quit:
				p.ticker.Stop()
				return
			}
		}
	}()
}

// Pause pauses the processor (stops processing but keeps running)
func (p *Processor) Pause() {
	select {
	case p.pause <- struct{}{}:
	default:
		// Channel is full, pause signal already sent
	}
}

// Resume resumes the processor
func (p *Processor) Resume() {
	select {
	case p.resume <- struct{}{}:
	default:
		// Channel is full, resume signal already sent
	}
}

// Stop halts the processor.
func (p *Processor) Stop() {
	close(p.quit)
	log.Println("Processor stopped.")
}
