## HmisCsvTwentyTwenty README

Importing and processing logic for HMIS CSV files in the 2020 HUD format.

This will:
1. pre-process the CSVs
2. import them into a data lake
3. run validations against the data lake
4. run necessary ETL to bring them into a structured, validated set of tables
5. bring any changes into the warehouse proper