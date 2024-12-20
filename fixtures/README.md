# Overview

The contents below are from the template: at [databricks-cli/../fixtures](https://github.com/databricks/cli/tree/main/libs/template/templates/default-python/template/%7B%7B.project_name%7D%7D/fixtures)

##  Fixtures
```
{{- /*
We don't want to have too many README.md files, since they
stand out so much. But we do need to have a file here to make
sure the folder is added to Git.
*/}}
```

This folder is reserved for fixtures, such as CSV files.

Below is an example of how to load fixtures as a data frame:

```python
import pandas as pd
import os

def get_absolute_path(*relative_parts):
    if 'dbutils' in globals():
        base_dir = os.path.dirname(dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()) # type: ignore
        path = os.path.normpath(os.path.join(base_dir, *relative_parts))
        return path if path.startswith("/Workspace") else "/Workspace" + path
    else:
        return os.path.join(*relative_parts)

csv_file = get_absolute_path("..", "fixtures", "mycsv.csv")
df = pd.read_csv(csv_file)
display(df)
```