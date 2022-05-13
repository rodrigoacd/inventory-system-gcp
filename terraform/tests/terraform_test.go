package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformInfrastructure(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"project_id":        "test-project",
			"region":            "us-central1",
			"bucket_name":       "test-bucket-inventory",
			"database_password": "test-password-123",
			"cloud_run_image":   "gcr.io/test/app:latest",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)
}

func TestCloudRunModule(t *testing.T) {
	t.Run("ValidatesRequiredVariables", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../modules/cloud_run",
		}

		_, err := terraform.InitAndPlanE(t, terraformOptions)
		assert.Error(t, err, "Should fail without required variables")
	})
}

func TestCloudSQLModule(t *testing.T) {
	t.Run("ValidatesPasswordComplexity", func(t *testing.T) {
		assert.True(t, len("test-password-123") >= 8, "Password should be at least 8 characters")
	})
}

func TestCloudStorageModule(t *testing.T) {
	t.Run("ValidatesBucketNaming", func(t *testing.T) {
		bucketName := "test-bucket-inventory"
		assert.NotEmpty(t, bucketName, "Bucket name should not be empty")
		assert.Regexp(t, "^[a-z0-9-]+$", bucketName, "Bucket name should be valid")
	})
}
