workspace "Open Path Boston Pathways" {

    model {
        assessor = person "Assessor" ""
        clarity = softwareSystem "Clarity" "An external HMIS"
        warehouse = softwareSystem "Warehouse" "The OpenPath warehouse" {
            warehouseApp = container "Web Application" "The Warehouse App" "Rails"
            s3bucket = container "S3 Bucket" "Interchange store for HMIS CSVs"
            warehouseDb = container "Warehouse DB" "Warehouse data model" "Postgres" "Database"

            warehouseApp -> warehouseDb "Stores CAS clients"
            warehouseApp -> s3bucket "Loads CSVs from Clarity"
        }

        cas = softwareSystem "CAS" "The OpenPath housing workflow system" {
            casApp = container "Web Application" "The CAS App" "Rails"
            casDb = container "CAS DB" "CAS data model" "Postgres" "Database"

            casApp -> warehouseDb "Reports CE data to"
            warehouseApp -> casDb "Syncs permitted clients to"
            casApp -> casDb "Stores client matching data"
        }

        dvAssessor = person "DV Assessor" "A DV Assessor"
        housingStaff = person "Housing Staff"

        assessor -> clarity "Assesses HMIS clients using"
        clarity -> warehouse "Sends assessments via HMIS CSV to"
        clarity -> warehouse "Sends contacts via S3 to"
        assessor -> warehouse "Verifies or uploads ROI to"
        dvAssessor -> cas "Assesses DV victim clients as de-identified clients in"
        housingStaff -> cas "Tracks housing workflow using"

    }

    views {
        systemLandscape "Pathways" "The OpenPath Pathways system context" {
            include *
            autoLayout
        }

        container warehouse "Warehouse" "The OpenPath warehouse" {
            include *
            autoLayout
        }

        container cas "CAS" "OpenPath CAS" {
            include *
            autoLayout
        }

        theme default
    }
}