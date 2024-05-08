# Liquibase <> Databricks Demo

Liquibase / Databricks Connector on v 1.1.5 (minimum required version)

## Steps to Reproduce this Demo 

1. Delete / Rename the changelogs that come with the demo (this is generated post-run). These are just for reference
2. Create DEV and PROD databases and warehouses (they can be the same warehouse and workspace)
3. Update your DEV and PROD database configs in your DEV and PROD liquibase.properties files
4. Run DDL on Database in DEV in DBSQL Manually to simulate active development (you can run the initial_sql.sql file in this repo, run all statements BEFORE the ALTER statements)
5. Generate DEV changelog by running <b> liquibase generateChangelog --defaultsFile=dev_liquibase.properties </b>
6. Now automatically get the diff changelog from DEV → PROD by running <b> liquibase diff-changelog –defaultsFile=liquibase.properties </b> (if this is your default you dont need to specify)
7. Review your new incremental PROD changelog – Make adjustments such as: Dependency preconditions, Run always conditions, Extra databricks-specific maintenance steps, add indexing DDL here
8. Run <b> liquibase update –defaultsFile=liquibase.properties </b> to do your PROD incremental deployment
9. Now add more changes to DEV! – Add columns, etc. etc. 
10. Run <b> liquibase diff-changelog </b> again to sync DEV and PROD changelog
11. Review again and then run liquibase update to PROD
12. Repeat as needed!