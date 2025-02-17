package main

import (
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"

	_ "github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

type TemperatureCorrection struct {
	Temperature float64
	Correction  float64
}

// Подключение в бд (докер
func DBconnect() *sql.DB {

	user := "testuser"
	password := "testpass"
	dbname := "testdb"
	host := "localhost"
	port := "5433"
	db, err := sql.Open("postgres", fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable", user, password, host, port, dbname))
	if err != nil {
		logrus.Fatalf("Failed to connect to database: %v", err)
		return nil
	}
	db.SetMaxOpenConns(30)
	db.SetMaxIdleConns(15)
	db.SetConnMaxLifetime(10 * time.Second)
	return db
}

// Интерполяция
func linearInterpolation(targetTemp float64, data []TemperatureCorrection) (float64, error) {
	if targetTemp < data[0].Temperature || targetTemp > data[len(data)-1].Temperature {
		fmt.Printf("Target temperature: %f, Min: %f, Max: %f\n", targetTemp, data[0].Temperature, data[len(data)-1].Temperature)
		return 0, fmt.Errorf("target temperature out of range: %f", targetTemp)
	}

	for i := 0; i < len(data)-1; i++ {
		if targetTemp >= data[i].Temperature && targetTemp <= data[i+1].Temperature {
			x0, y0 := data[i].Temperature, data[i].Correction
			x1, y1 := data[i+1].Temperature, data[i+1].Correction
			return y0 + (y1-y0)*(targetTemp-x0)/(x1-x0), nil
		}
	}

	return 0, fmt.Errorf("target temperature not found in range: %f", targetTemp)
}

func main() {
	// var data []TemperatureCorrection
	var temp, correction float64
	wg := sync.WaitGroup{}
	mu := sync.Mutex{}
	db := DBconnect()
	count := 0
	start := time.Now()
	for i := 0.0; i <= 40.0; i += 0.01 { //4000 итераций
		wg.Add(1)
		go func(targetTemp float64) {
			defer wg.Done()
			query := "SELECT temperature, correction FROM calc_temperatures_correction ORDER BY temperature ASC;"

			rows, err := db.Query(query)
			if err != nil {
				log.Fatal(err)
			}
			defer rows.Close()

			var localData []TemperatureCorrection

			mu.Lock()
			for rows.Next() {
				if err := rows.Scan(&temp, &correction); err != nil {
					log.Fatal(err)
				}
				localData = append(localData, TemperatureCorrection{Temperature: temp, Correction: correction})

			}

			_, err = linearInterpolation(targetTemp, localData)

			clear(localData)
			mu.Unlock()
			mu.Lock()
			count += 1
			mu.Unlock()

		}(i)
	}

	wg.Wait()
	end := time.Since(start)
	fmt.Println(end, count)
}
