# Testing Overview

For the most part Databricks is tightly coupled to the Workspace and a running compute instance setup via the profile.

## Requirements

For the cluster instance, PyTest needs to be installed. 

## Limitations

Ideally you can run PySpark in local mode for basic dataframe testing; however, the pyspark package conflicts with databricks-connect package -- see [conflicting-pyspark-installations](https://docs.databricks.com/en/dev-tools/databricks-connect/python/troubleshooting.html#conflicting-pyspark-installations).

