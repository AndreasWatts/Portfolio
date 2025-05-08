# Creating a Dimensional Model (Star Schema) in Databricks
For this project I built a dimensional model on car sales data using PySpark and Databricks.

**Tech Stack:** Azure Cloud, Azure SQL Server, Azure Data Factory, Databricks, Python (PySpark, Pandas)

## Project Architecture
Data is extracted from an Azure cloud SQL server using Azure Data Factory to Azure Data Lake Gen2 and saved as Parquet files. The data is then transformed within Databricks and then modelled into a star schema consisting of a fact table and multiple dimensions.
![](https://media.contra.com/image/upload/fl_progressive/q_auto:best/ktc4wkdffxugepq5zprl.webp)

## ETL
Extracting the data from the SQL server to the Data Lake was done with Azure Data Factory.

![](https://media.contra.com/image/upload/fl_progressive/q_auto:best/wnza0b1cp8jldfuegsgi.webp)

## Notebooks

![](https://media.contra.com/image/upload/fl_progressive/q_auto:best/h4w1zpiojnzssdlv4obd.webp)

## Workflow

![](https://media.contra.com/image/upload/fl_progressive/q_auto:best/hju8457aee3gnvcyqyoc.webp)
