package processor

import (
	"log"
	"time"

	"github.com/imdawon/personalos/storage"
)

// Processor handles the aggregation of raw events into sessions.
type Processor struct {
	store  *storage.DBStore
	ticker *time.Ticker
	quit   chan struct{}
}

// NewProcessor creates a new Processor instance.
func NewProcessor(store *storage.DBStore, interval time.Duration) *Processor {
	return &Processor{
		store:  store,
		ticker: time.NewTicker(interval),
		quit:   make(chan struct{}),
	}
}

// Start begins the periodic processing of events.
func (p *Processor) Start() {
	log.Println("Processor started...")
	go func() {
		for {
			select {
			case <-p.ticker.C:
				log.Println("Processor running...")
				if err := p.store.ProcessRawEvents(); err != nil {
					log.Printf("Error processing raw events: %v", err)
				}
			case <-p.quit:
				p.ticker.Stop()
				return
			}
		}
	}()
}

// Stop halts the processor.
func (p *Processor) Stop() {
	close(p.quit)
	log.Println("Processor stopped.")
}
