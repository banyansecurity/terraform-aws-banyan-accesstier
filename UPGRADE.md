# Upgrading your AccessTier

This document explains how to upgrade your AccessTier to a newer version with zero downtime.

 1. (Optional) If you have pinned your deployment to a particular version of Netagent, update the value of `package_name` to match the version you want to deploy.

    ```hcl
    module "aws_accesstier" {
        package_name = "banyan-netagent-1.26.1"
    }
    ```

 2. Run `terraform plan` to confirm that only the auto-scaling group and launch configuration will be updated:

    ```text
    Terraform will perform the following actions:

    # aws_autoscaling_group.asg will be updated in-place
    # aws_launch_configuration.conf must be replaced
    ```

 3. Run `terraform apply` to update the ASG and launch configuration.

 4. Open the AWS management console in your browser. Navigate to **EC2 > Auto-Scaling Groups** and select your ASG. Click on **Instance refresh**.

 5. Click the **Start instance refresh** button. Change the minimum healthy percentage to 50% and the instance warmup time to 180 seconds. Click **Start**.

 6. After a few minutes, the status of the instance refresh should change to "Successful". 

 7. Log into the Banyan Command Center to verify that the new AccessTier instances are reporting. Navigate to **Directory & Infrastructure > AccessTiers** to see them.
