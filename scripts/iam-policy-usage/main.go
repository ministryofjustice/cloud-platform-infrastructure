package main

import (
	"html/template"
	"iam-policy-usage/aws"
	"iam-policy-usage/charts"
	"iam-policy-usage/utils"
	"log"

	"github.com/gofiber/fiber/v2"
)

var (
	bucket = "cloud-platform-hoodaw-reports"
	key    = "policy_usage.csv"
)

func main() {
	homePath := "templates/home.gohtml"

	app := fiber.New()

	app.Get("/", func(c *fiber.Ctx) error {
		tmpl, err := template.ParseFiles(homePath)
		if err != nil {
			return err
		}
		// You can pass any data you want to the home template here
		return c.Type("html").SendString(utils.ExecuteTemplateToString(tmpl, "home", nil))
	})

	// Serve nav.js and other static assets from templates directory
	app.Static("/templates", "./templates")

	// Dynamic chart routes
	app.Get("/owners", func(c *fiber.Ctx) error {
		chart := charts.PieChart{}
		r, err := aws.DownloadCSVFromS3ToReader(bucket, key)
		if err != nil {
			return err
		}
		err = chart.PolicyOwners(r)
		if err != nil {
			return err
		}
		tmpl, err := template.ParseFiles("templates/template.gohtml")
		if err != nil {
			return err
		}
		return c.Type("html").SendString(utils.ExecuteTemplateToString(tmpl, "charts", chart))
	})

	app.Get("/stale1yr", func(c *fiber.Ctx) error {
		chart := charts.PieChart{}
		r, err := aws.DownloadCSVFromS3ToReader(bucket, key)
		if err != nil {
			return err
		}
		err = chart.StalePolicies(r, "Stale (>1yr)")
		if err != nil {
			return err
		}
		tmpl, err := template.ParseFiles("templates/template.gohtml")
		if err != nil {
			return err
		}
		return c.Type("html").SendString(utils.ExecuteTemplateToString(tmpl, "charts", chart))
	})

	app.Get("/stale30day", func(c *fiber.Ctx) error {
		chart := charts.PieChart{}
		r, err := aws.DownloadCSVFromS3ToReader(bucket, key)
		if err != nil {
			return err
		}
		err = chart.StalePolicies(r, "Stale (>30d)")
		if err != nil {
			return err
		}
		tmpl, err := template.ParseFiles("templates/template.gohtml")
		if err != nil {
			return err
		}
		return c.Type("html").SendString(utils.ExecuteTemplateToString(tmpl, "charts", chart))
	})

	log.Fatal(app.Listen(":3000"))
}
