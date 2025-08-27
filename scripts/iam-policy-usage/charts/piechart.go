package charts

import (
	"encoding/csv"
	"io"
	"sort"
)

type PieChartData struct {
	Label string
	Value float64
}

type PieChart struct {
	Data     []PieChartData
	Title    string
	Subtitle string
}

func (p *PieChart) PolicyOwners(r io.Reader) error {
	reader := csv.NewReader(r)
	records, err := reader.ReadAll()
	if err != nil {
		return err
	}

	if len(records) == 0 {
		return nil // nothing to process
	}

	// Map to count policies per owner
	ownerCount := make(map[string]float64)

	// Find the index for the Owner column
	header := records[0]
	ownerIdx := -1
	for i, col := range header {
		if col == "Owner" {
			ownerIdx = i
			break
		}
	}
	if ownerIdx == -1 {
		return nil // Owner column not found
	}

	// Count policies per owner, skip header
	for i, record := range records {
		if i == 0 {
			continue
		}
		if len(record) <= ownerIdx {
			continue
		}
		owner := record[ownerIdx]
		if owner == "" {
			owner = "(Tagless)"
		}
		ownerCount[owner]++
	}

	// Build PieChartData from map and sort by value descending
	var data []PieChartData
	for owner, count := range ownerCount {
		data = append(data, PieChartData{Label: owner, Value: count})
	}
	sort.Slice(data, func(i, j int) bool {
		return data[i].Value > data[j].Value
	})
	p.Data = data
	p.Title = "Policy Owners"
	p.Subtitle = "Number of Policies per Owner"
	return nil
}

func (p *PieChart) StalePolicies(r io.Reader, stale string) error {
	reader := csv.NewReader(r)
	records, err := reader.ReadAll()
	if err != nil {
		return err
	}

	if len(records) == 0 {
		return nil // nothing to process
	}

	// Find the index for the Owner and Flag columns
	header := records[0]
	ownerIdx, flagIdx := -1, -1
	for i, col := range header {
		if col == "Owner" {
			ownerIdx = i
		}
		if col == "Flag" {
			flagIdx = i
		}
	}
	if ownerIdx == -1 || flagIdx == -1 {
		return nil // Required columns not found
	}

	// Map to count stale policies per owner
	staleCount := make(map[string]float64)

	// Count policies with flag exactly 'Stale (>1y)', skip header
	for i, record := range records {
		if i == 0 {
			continue
		}
		if len(record) <= ownerIdx || len(record) <= flagIdx {
			continue
		}
		flag := record[flagIdx]
		if flag == stale {
			owner := record[ownerIdx]
			if owner == "" {
				owner = "(Tagless)"
			}
			staleCount[owner]++
		}
	}

	// Build PieChartData from map and sort by value descending
	var data []PieChartData
	for owner, count := range staleCount {
		data = append(data, PieChartData{Label: owner, Value: count})
	}
	// Sort by Value descending
	sort.Slice(data, func(i, j int) bool {
		return data[i].Value > data[j].Value
	})
	p.Data = data
	p.Title = "Stale Policies"
	p.Subtitle = "Number of Stale Policies per Owner: " + stale
	return nil
}

func (p *PieChart) UnattachedPolicies(r io.Reader) error {
	reader := csv.NewReader(r)
	records, err := reader.ReadAll()
	if err != nil {
		return err
	}

	if len(records) == 0 {
		return nil // nothing to process
	}

	// Find the index for the Owner column
	header := records[0]
	ownerIdx := -1
	for i, col := range header {
		if col == "Owner" {
			ownerIdx = i
			break
		}
	}
	if ownerIdx == -1 {
		return nil // Owner column not found
	}

	// Always use column 4 (index 3) for Flag
	flagIdx := 3

	// Map to count unattached policies per owner
	unattachedCount := make(map[string]float64)

	// Count policies with flag exactly 'Not Attached', skip header
	for i, record := range records {
		if i == 0 {
			continue
		}
		if len(record) <= ownerIdx || len(record) <= flagIdx {
			continue
		}
		flag := record[flagIdx]
		if flag == "Not Attached" {
			owner := record[ownerIdx]
			if owner == "" {
				owner = "(Tagless)"
			}
			unattachedCount[owner]++
		}
	}

	// Build PieChartData from map and sort by value descending
	var data []PieChartData
	for owner, count := range unattachedCount {
		data = append(data, PieChartData{Label: owner, Value: count})
	}
	// Sort by Value descending
	sort.Slice(data, func(i, j int) bool {
		return data[i].Value > data[j].Value
	})
	p.Data = data
	p.Title = "Unattached Policies"
	p.Subtitle = "Number of Unattached Policies per Owner"
	return nil
}
