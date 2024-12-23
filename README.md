# Liquibase <> Databricks Demo

Liquibase / Databricks Connector on v 1.1.5 (minimum required version)

## Steps to Reproduce this Demo 

1. Delete / Rename the changelogs that come with the demo (this is generated post-run). These are just for reference
2. Run DDL on Database in DEV in DBSQL Manually to simulate active development (you can run the initial_sql.sql file in this repo, run all statements BEFORE the ALTER statements)
3. Update your DEV and PROD database configs in your DEV and PROD liquibase.properties files - in the PROD properites file, the DEV database is the reference database. 
4. Generate DEV changelog by running <b> liquibase generateChangelog --defaultsFile=dev_liquibase.properties </b>
5. Now automatically get the diff changelog from DEV → PROD by running <b> liquibase diff-changelog –defaultsFile=liquibase.properties </b> (if this is your default you dont need to specify)
6. Review your new incremental PROD changelog – Make adjustments such as: Dependency preconditions, Run always conditions, Extra databricks-specific maintenance steps, add indexing DDL here
7. Run <b> liquibase update –defaultsFile=liquibase.properties </b> to do your PROD incremental deployment
8. Now add more changes to DEV! – Add columns, etc. etc. 
9. Run <b> liquibase diff-changelog </b> again to sync DEV and PROD changelog
10. Review again and then run liquibase update to PROD
11. Repeat as needed!